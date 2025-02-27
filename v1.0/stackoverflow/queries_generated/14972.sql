-- Performance benchmarking query to retrieve statistics on posts, users, and their interactions.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(bp.BadgeCount, 0) AS BadgeCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) bp ON u.Id = bp.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            UserId
    ) v ON u.Id = v.UserId
), CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate AS PostCreationDate,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        us.UserId,
        us.DisplayName AS UserDisplayName,
        us.Reputation,
        us.BadgeCount,
        us.VoteCount
    FROM 
        PostStats ps
    JOIN 
        Users us ON ps.OwnerUserId = us.Id
)

SELECT 
    PostId,
    Title,
    PostCreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    UserId,
    UserDisplayName,
    Reputation,
    BadgeCount,
    VoteCount
FROM 
    CombinedStats
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100; -- Limit results to top 100 based on score and view count
