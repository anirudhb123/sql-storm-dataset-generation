WITH RecursiveTags AS (
    SELECT
        Id,
        TagName,
        Count,
        1 AS Depth
    FROM Tags
    WHERE IsModeratorOnly = 0  -- Focusing on non-moderator tags

    UNION ALL

    SELECT
        t.Id,
        t.TagName,
        t.Count,
        rt.Depth + 1
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN RecursiveTags rt ON rt.Id = t.Id
    WHERE rt.Depth < 3  -- Limit the depth for recursion
),

PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        STRING_AGG(DISTINCT tt.TagName, ', ') AS AssociatedTags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN RecursiveTags tt ON p.Tags LIKE '%' || tt.TagName || '%'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),

VoteStatistics AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),

CommentCount AS (
    SELECT
        PostId,
        COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
)

SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.OwnerName,
    COALESCE(vs.UpVotes, 0) AS Upvotes,
    COALESCE(vs.DownVotes, 0) AS Downvotes,
    COALESCE(cc.TotalComments, 0) AS CommentCount,
    pd.AssociatedTags
FROM PostDetails pd
LEFT JOIN VoteStatistics vs ON pd.PostId = vs.PostId
LEFT JOIN CommentCount cc ON pd.PostId = cc.PostId
ORDER BY pd.Score DESC, pd.CreationDate DESC
LIMIT 100;
