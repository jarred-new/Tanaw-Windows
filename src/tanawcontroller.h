#pragma once

#include "channelmodel.h"

#include <QObject>
#include <QNetworkAccessManager>
#include <QUrl>
#include <QVariantMap>

class QNetworkReply;

class TanawController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ChannelModel *channelModel READ channelModel CONSTANT)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QString playlistSourceUrl READ playlistSourceUrl NOTIFY playlistSourceUrlChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int channelCount READ channelCount NOTIFY channelCountChanged)

public:
    explicit TanawController(QObject *parent = nullptr);

    ChannelModel *channelModel();
    QString statusText() const;
    QString playlistSourceUrl() const;
    bool loading() const;
    int channelCount() const;

    Q_INVOKABLE bool addPlaylist(const QString &playlistUrl);
    Q_INVOKABLE void refreshPlaylist();
    Q_INVOKABLE QVariantMap channelInfo(int row) const;
    Q_INVOKABLE void removeChannel(int row);
    Q_INVOKABLE void toggleFavorite(int row);
    Q_INVOKABLE void copyStreamUrl(const QString &url);
    Q_INVOKABLE void shareStreamUrl(const QString &url);
    Q_INVOKABLE void importChannels(const QUrl &fileUrl);
    Q_INVOKABLE void exportChannels(const QUrl &fileUrl);

signals:
    void statusTextChanged();
    void playlistSourceUrlChanged();
    void loadingChanged();
    void channelCountChanged();
    void notification(const QString &message);
    void playlistError(const QString &message);

private:
    void loadSavedPlaylist();
    void savePlaylist();
    void setStatusText(const QString &text);
    void setLoading(bool loading);
    void downloadPlaylist(const QString &playlistUrl);
    void parsePlaylistLine(const QString &line, QList<Channel> &channels, QString &pendingName, QString &pendingLogo) const;
    QList<Channel> parsePlaylist(const QByteArray &data, QString *error) const;
    QString parseAttribute(const QString &line, const QString &attribute) const;

    ChannelModel m_channelModel;
    QNetworkAccessManager m_network;
    QNetworkReply *m_reply = nullptr;
    QString m_statusText;
    QString m_playlistSourceUrl;
    bool m_loading = false;
};