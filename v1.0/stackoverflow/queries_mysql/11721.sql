
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        u.Reputation AS OwnerReputation,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) -CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS t ON TRUE
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
        p.CommentCount, p.FavoriteCount, p.AcceptedAnswerId, p.OwnerUserId, 
        u.Reputation
),
VoteStats AS (
    SELECT
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM
        Votes
    GROUP BY
        PostId
)
SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.AcceptedAnswerId,
    ps.OwnerUserId,
    ps.OwnerReputation,
    ps.Tags,
    COALESCE(vs.VoteCount, 0) AS TotalVotes,
    COALESCE(vs.Upvotes, 0) AS TotalUpvotes,
    COALESCE(vs.Downvotes, 0) AS TotalDownvotes
FROM
    PostStats ps
LEFT JOIN
    VoteStats vs ON ps.PostId = vs.PostId
ORDER BY
    ps.CreationDate DESC
LIMIT 100;
