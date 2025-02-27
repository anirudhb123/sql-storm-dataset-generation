-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id), 0) AS VoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' -- Filter by recent posts
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN u.Reputation IS NOT NULL THEN u.Reputation ELSE 0 END) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.VoteCount,
        us.UserId,
        us.DisplayName AS UserDisplayName,
        us.BadgeCount,
        us.TotalReputation
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.AnswerCount > 0 AND ps.OwnerUserId = u.Id -- Considering only posts with answers by users
    LEFT JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    VoteCount,
    UserDisplayName,
    BadgeCount,
    TotalReputation
FROM 
    CombinedStats
ORDER BY 
    CreationDate DESC; -- Order by recent posts
