
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        STRING_AGG(DISTINCT ph.Comment, ',') AS HistoryComments,
        STRING_AGG(DISTINCT b.Name, ',') AS BadgesEarned
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TagStatistics AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(Tags, '>,<')
    WHERE Tags IS NOT NULL
    GROUP BY value
),
TopTags AS (
    SELECT TOP 10 TagName, PostCount
    FROM TagStatistics
    ORDER BY PostCount DESC
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.Tags,
    pd.OwnerName,
    pd.UpVotes,
    pd.DownVotes,
    pd.HistoryComments,
    pd.BadgesEarned,
    tt.TagName,
    tt.PostCount
FROM PostDetails pd
LEFT JOIN TopTags tt ON pd.Tags LIKE '%' + tt.TagName + '%'
ORDER BY pd.Score DESC, pd.ViewCount DESC;
