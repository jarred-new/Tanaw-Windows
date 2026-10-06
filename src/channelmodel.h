#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QString>

struct Channel {
    QString name;
    QString logo;
    QString url;
    bool favorite = false;
};

class ChannelModel final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    Q_PROPERTY(bool favoritesOnly READ favoritesOnly WRITE setFavoritesOnly NOTIFY favoritesOnlyChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        LogoRole,
        UrlRole,
        FavoriteRole
    };
    Q_ENUM(Role)

    explicit ChannelModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filterText() const;
    void setFilterText(const QString &text);
    bool favoritesOnly() const;
    void setFavoritesOnly(bool favoritesOnly);

    void setChannels(const QList<Channel> &channels);
    void removeAt(int row);
    void toggleFavorite(int row);
    Channel channelAt(int row) const;
    const QList<Channel> &channels() const;

signals:
    void filterTextChanged();
    void favoritesOnlyChanged();

private:
    void rebuildVisibleRows();

    QList<Channel> m_channels;
    QList<int> m_visibleRows;
    QString m_filterText;
    bool m_favoritesOnly = false;
};