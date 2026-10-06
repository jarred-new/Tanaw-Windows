#include "tanawcontroller.h"

#include <QClipboard>
#include <QDesktopServices>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QUrl>
#include <QUrlQuery>
#include <QGuiApplication>

TanawController::TanawController(QObject *parent)
    : QObject(parent)
{
    loadSavedPlaylist();
}

ChannelModel *TanawController::channelModel()
{
    return &m_channelModel;
}

QString TanawController::statusText() const
{
    return m_statusText;
}

QString TanawController::playlistSourceUrl() const
{
    return m_playlistSourceUrl;
}

bool TanawController::loading() const
{
    return m_loading;
}

int TanawController::channelCount() const
{
    return m_channelModel.rowCount();
}

bool TanawController::addPlaylist(const QString &playlistUrl)
{
    const QString trimmedUrl = playlistUrl.trimmed();
    const QUrl url(trimmedUrl);

    if (!url.isValid()
        || (url.scheme() != QStringLiteral("http")
            && url.scheme() != QStringLiteral("https"))) {
        emit notification(QStringLiteral("Enter a valid HTTP/HTTPS URL"));
        return false;
    }

    downloadPlaylist(trimmedUrl);
    return true;
}

void TanawController::refreshPlaylist()
{
    if (m_playlistSourceUrl.isEmpty()) {
        emit notification(QStringLiteral("No playlist URL is saved yet"));
        return;
    }

    downloadPlaylist(m_playlistSourceUrl);
}

QVariantMap TanawController::channelInfo(int row) const
{
    const Channel channel = m_channelModel.channelAt(row);
    return {
        {QStringLiteral("channelNumber"), row},
        {QStringLiteral("name"), channel.name},
        {QStringLiteral("logo"), channel.logo},
        {QStringLiteral("url"), channel.url},
        {QStringLiteral("favorite"), channel.favorite}
    };
}

void TanawController::removeChannel(int row)
{
    const Channel channel = m_channelModel.channelAt(row);
    if (channel.name.isEmpty() && channel.url.isEmpty()) {
        return;
    }

    m_channelModel.removeAt(row);
    savePlaylist();
    emit channelCountChanged();
    emit notification(QStringLiteral("%1 removed").arg(channel.name));
}

void TanawController::toggleFavorite(int row)
{
    m_channelModel.toggleFavorite(row);
    savePlaylist();
}

void TanawController::copyStreamUrl(const QString &url)
{
    if (url.trimmed().isEmpty()) {
        emit notification(QStringLiteral("This channel has no stream URL"));
        return;
    }

    QGuiApplication::clipboard()->setText(url);
    emit notification(QStringLiteral("Stream URL copied"));
}

void TanawController::shareStreamUrl(const QString &url)
{
    if (url.trimmed().isEmpty()) {
        emit notification(QStringLiteral("This channel has no stream URL"));
        return;
    }

    QUrl shareUrl(QStringLiteral("mailto:"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("subject"), QStringLiteral("Tanaw IPTV channel"));
    query.addQueryItem(QStringLiteral("body"), url);
    shareUrl.setQuery(query);

    if (!QDesktopServices::openUrl(shareUrl)) {
        copyStreamUrl(url);
        emit notification(QStringLiteral("No mail app is configured; stream URL copied"));
    } else {
        emit notification(QStringLiteral("Opened your default mail app"));
    }
}

void TanawController::importChannels(const QUrl &fileUrl)
{
    if (!fileUrl.isLocalFile()) {
        emit notification(QStringLiteral("Choose a local JSON file"));
        return;
    }

    QFile file(fileUrl.toLocalFile());
    if (!file.open(QIODevice::ReadOnly)) {
        emit notification(QStringLiteral("Unable to open file: %1").arg(file.errorString()));
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isArray()) {
        const QString reason = parseError.error != QJsonParseError::NoError
                                   ? parseError.errorString()
                                   : QStringLiteral("Expected a JSON array of channels");
        emit notification(QStringLiteral("Unable to import channels: %1").arg(reason));
        return;
    }

    QList<Channel> channels;
    const QJsonArray array = document.array();
    for (qsizetype i = 0; i < array.size(); ++i) {
        if (!array.at(i).isObject()) {
            emit notification(QStringLiteral("Unable to import channels: item %1 is not an object")
                                  .arg(i + 1));
            return;
        }

        const QJsonObject object = array.at(i).toObject();
        if (!object.value(QStringLiteral("name")).isString()
            || !object.value(QStringLiteral("url")).isString()
            || (!object.value(QStringLiteral("logo")).isUndefined()
                && !object.value(QStringLiteral("logo")).isString())
            || (!object.value(QStringLiteral("favorite")).isUndefined()
                && !object.value(QStringLiteral("favorite")).isBool())) {
            emit notification(QStringLiteral("Unable to import channels: item %1 has invalid fields")
                                  .arg(i + 1));
            return;
        }

        channels.append(Channel{
            object.value(QStringLiteral("name")).toString(),
            object.value(QStringLiteral("logo")).toString(),
            object.value(QStringLiteral("url")).toString(),
            object.value(QStringLiteral("favorite")).toBool()
        });
    }

    m_channelModel.setChannels(channels);
    savePlaylist();
    emit channelCountChanged();
    setStatusText(QStringLiteral("%1 channels loaded").arg(channels.size()));
    emit notification(QStringLiteral("Channel list imported"));
}

void TanawController::exportChannels(const QUrl &fileUrl)
{
    if (!fileUrl.isLocalFile()) {
        emit notification(QStringLiteral("Choose a local file"));
        return;
    }

    QJsonArray array;
    for (const Channel &channel : m_channelModel.channels()) {
        array.append(QJsonObject{
            {QStringLiteral("name"), channel.name},
            {QStringLiteral("logo"), channel.logo},
            {QStringLiteral("url"), channel.url},
            {QStringLiteral("favorite"), channel.favorite}
        });
    }

    QSaveFile file(fileUrl.toLocalFile());
    if (!file.open(QIODevice::WriteOnly)) {
        emit notification(QStringLiteral("Unable to save file: %1").arg(file.errorString()));
        return;
    }

    const QByteArray json = QJsonDocument(array).toJson(QJsonDocument::Indented);
    if (file.write(json) != json.size() || !file.commit()) {
        emit notification(QStringLiteral("Unable to save file: %1").arg(file.errorString()));
        return;
    }

    emit notification(QStringLiteral("Channel list exported"));
}

void TanawController::loadSavedPlaylist()
{
    QSettings settings(QStringLiteral("Tanaw"), QStringLiteral("Tanaw"));
    const QByteArray savedJson = settings.value(QStringLiteral("channels")).toByteArray();
    const QJsonDocument document = QJsonDocument::fromJson(savedJson);

    QList<Channel> channels;
    if (document.isArray()) {
        for (const QJsonValue &value : document.array()) {
            const QJsonObject object = value.toObject();
            Channel channel;
            channel.name = object.value(QStringLiteral("name")).toString();
            channel.logo = object.value(QStringLiteral("logo")).toString();
            channel.url = object.value(QStringLiteral("url")).toString();
            channel.favorite = object.value(QStringLiteral("favorite")).toBool();
            channels.append(channel);
        }
    }

    m_playlistSourceUrl = settings.value(QStringLiteral("playlistSourceUrl")).toString();
    m_channelModel.setChannels(channels);

    if (!m_playlistSourceUrl.isEmpty()) {
        emit playlistSourceUrlChanged();
    }

    setStatusText(channels.isEmpty()
                      ? QStringLiteral("No channels loaded")
                      : QStringLiteral("%1 channels loaded").arg(channels.size()));
    emit channelCountChanged();
}

void TanawController::savePlaylist()
{
    QJsonArray array;
    for (const Channel &channel : m_channelModel.channels()) {
        array.append(QJsonObject{
            {QStringLiteral("name"), channel.name},
            {QStringLiteral("logo"), channel.logo},
            {QStringLiteral("url"), channel.url},
            {QStringLiteral("favorite"), channel.favorite}
        });
    }

    QSettings settings(QStringLiteral("Tanaw"), QStringLiteral("Tanaw"));
    settings.setValue(QStringLiteral("channels"),
                      QJsonDocument(array).toJson(QJsonDocument::Compact));
    settings.setValue(QStringLiteral("playlistSourceUrl"), m_playlistSourceUrl);
    settings.sync();
}

void TanawController::setStatusText(const QString &text)
{
    if (m_statusText == text) {
        return;
    }

    m_statusText = text;
    emit statusTextChanged();
}

void TanawController::setLoading(bool loading)
{
    if (m_loading == loading) {
        return;
    }

    m_loading = loading;
    emit loadingChanged();
}

void TanawController::downloadPlaylist(const QString &playlistUrl)
{
    if (m_reply) {
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    setLoading(true);
    setStatusText(QStringLiteral("Loading playlist..."));

    QNetworkRequest request{QUrl(playlistUrl)};
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      QStringLiteral("Tanaw IPTV Player"));
    request.setRawHeader("Accept", "*/*");
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);

    m_reply = m_network.get(request);
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        QNetworkReply *reply = m_reply;
        m_reply = nullptr;

        const QByteArray data = reply->readAll();
        const QString networkError = reply->error() == QNetworkReply::NoError
                                         ? QString()
                                         : reply->errorString();
        const int statusCode = reply->attribute(
                                    QNetworkRequest::HttpStatusCodeAttribute)
                                    .toInt();
        reply->deleteLater();

        setLoading(false);

        if (!networkError.isEmpty()) {
            setStatusText(QStringLiteral("Failed to load playlist"));
            emit playlistError(networkError);
            return;
        }

        if (statusCode < 200 || statusCode >= 300) {
            const QString error = QStringLiteral("HTTP %1").arg(statusCode);
            setStatusText(QStringLiteral("Failed to load playlist"));
            emit playlistError(error);
            return;
        }

        QString parseError;
        const QList<Channel> channels = parsePlaylist(data, &parseError);
        if (!parseError.isEmpty()) {
            setStatusText(QStringLiteral("Failed to load playlist"));
            emit playlistError(parseError);
            return;
        }

        m_playlistSourceUrl = reply->url().toString();
        emit playlistSourceUrlChanged();
        m_channelModel.setChannels(channels);
        savePlaylist();
        setStatusText(QStringLiteral("%1 channels loaded").arg(channels.size()));
        emit channelCountChanged();
        emit notification(QStringLiteral("Playlist loaded"));
    });
}

void TanawController::parsePlaylistLine(const QString &line, QList<Channel> &channels, QString &pendingName, QString &pendingLogo) const
{
    if (line.startsWith(
            QStringLiteral("#EXTINF"),
            Qt::CaseInsensitive)) {

        const int comma = line.indexOf(',');

        pendingName =
            comma >= 0
                ? line.mid(comma + 1).trimmed()
                : QStringLiteral("Unknown Channel");

        if (pendingName.isEmpty()) {
            pendingName = QStringLiteral("Unknown Channel");
        }

        pendingLogo = parseAttribute(
            line,
            QStringLiteral("tvg-logo"));

        return;
    }

    if (line.startsWith('#')) {
        return;
    }

    if (!pendingName.isEmpty()) {
        channels.append(
            Channel{
                pendingName,
                pendingLogo,
                line,
                false
            });

        pendingName.clear();
        pendingLogo.clear();
    }
}

QList<Channel> TanawController::parsePlaylist(
    const QByteArray &data,
    QString *error) const
{
    QList<Channel> channels;

    QString pendingName;
    QString pendingLogo;

    const QString text = QString::fromUtf8(data);

    int start = 0;
    const int size = text.size();

    while (start < size) {
        int end = text.indexOf('\n', start);

        if (end < 0) {
            end = size;
        }

        QString line = text.mid(start, end - start);

        if (line.endsWith('\r')) {
            line.chop(1);
        }

        line = line.trimmed();

        if (!line.isEmpty()) {
            parsePlaylistLine(
                line,
                channels,
                pendingName,
                pendingLogo);
        }

        start = end + 1;
    }

    if (channels.isEmpty()) {
        if (error) {
            *error = QStringLiteral(
                "No channels were found in this M3U playlist");
        }
    }

    return channels;
}

QString TanawController::parseAttribute(const QString &line, const QString &attribute) const
{
    const QRegularExpression expression(
        QStringLiteral("%1\\s*=\\s*\"([^\"]*)\"")
            .arg(QRegularExpression::escape(attribute)));
    const QRegularExpressionMatch match = expression.match(line);
    return match.hasMatch() ? match.captured(1) : QString();
}