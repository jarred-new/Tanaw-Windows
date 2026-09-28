#include "channelmodel.h"

#include <QVariant>

ChannelModel::ChannelModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ChannelModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_visibleRows.size();
}

QVariant ChannelModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visibleRows.size()) {
        return {};
    }

    const Channel &channel = m_channels.at(m_visibleRows.at(index.row()));
    switch (role) {
    case NameRole:
        return channel.name;
    case LogoRole:
        return channel.logo;
    case UrlRole:
        return channel.url;
    case FavoriteRole:
        return channel.favorite;
    case Qt::DisplayRole:
        return channel.name;
    default:
        return {};
    }
}

QHash<int, QByteArray> ChannelModel::roleNames() const
{
    return {
        {NameRole, "name"},
        {LogoRole, "logo"},
        {UrlRole, "url"},
        {FavoriteRole, "favorite"}
    };
}

QString ChannelModel::filterText() const
{
    return m_filterText;
}

void ChannelModel::setFilterText(const QString &text)
{
    if (m_filterText == text) {
        return;
    }

    m_filterText = text;
    rebuildVisibleRows();
    emit filterTextChanged();
}

void ChannelModel::setChannels(const QList<Channel> &channels)
{
    beginResetModel();
    m_channels = channels;
    rebuildVisibleRows();
    endResetModel();
}

void ChannelModel::removeAt(int row)
{
    if (row < 0 || row >= m_visibleRows.size()) {
        return;
    }

    const int sourceRow = m_visibleRows.at(row);
    beginRemoveRows(QModelIndex(), row, row);
    m_channels.removeAt(sourceRow);
    m_visibleRows.removeAt(row);
    for (int &visibleRow : m_visibleRows) {
        if (visibleRow > sourceRow) {
            --visibleRow;
        }
    }
    endRemoveRows();
}

void ChannelModel::toggleFavorite(int row)
{
    if (row < 0 || row >= m_visibleRows.size()) {
        return;
    }

    const int sourceRow = m_visibleRows.at(row);
    m_channels[sourceRow].favorite = !m_channels.at(sourceRow).favorite;
    const QModelIndex changed = index(row);
    emit dataChanged(changed, changed, {FavoriteRole});
}

Channel ChannelModel::channelAt(int row) const
{
    if (row < 0 || row >= m_visibleRows.size()) {
        return {};
    }

    return m_channels.at(m_visibleRows.at(row));
}

QList<Channel> ChannelModel::channels() const
{
    return m_channels;
}

void ChannelModel::rebuildVisibleRows()
{
    m_visibleRows.clear();
    const QString query = m_filterText.trimmed();

    for (int i = 0; i < m_channels.size(); ++i) {
        if (query.isEmpty()
            || m_channels.at(i).name.contains(query, Qt::CaseInsensitive)) {
            m_visibleRows.append(i);
        }
    }
}