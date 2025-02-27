WITH PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Consider only Questions
    GROUP BY
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        pht.Name AS HistoryTypeName
    FROM
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.BadgeCount,
    pd.TagNames,
    STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ' (', ph.HistoryTypeName, '): ', ph.Comment), '; ') AS HistoryComments
FROM
    PostDetails pd
LEFT JOIN PostHistoryDetails ph ON pd.PostId = ph.PostId
GROUP BY
    pd.PostId, pd.Title, pd.OwnerDisplayName, pd.CommentCount, pd.UpVoteCount, pd.DownVoteCount, pd.BadgeCount, pd.TagNames
ORDER BY
    pd.CommentCount DESC, pd.UpVoteCount DESC;
