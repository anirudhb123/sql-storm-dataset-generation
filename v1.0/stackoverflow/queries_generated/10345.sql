-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        EXTRACT(EPOCH FROM (NOW() - p.CreationDate)) AS AgeInSeconds
    FROM 
        Posts p
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.BadgeCount,
    u.UpVoteCount,
    u.DownVoteCount,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.AgeInSeconds
FROM 
    UserStats u
JOIN 
    PostStats p ON u.UserId = p.OwnerUserId -- Assuming we want to join based on posts owned by user
ORDER BY 
    u.Reputation DESC, p.ViewCount DESC
LIMIT 100; -- Limit to top 100 results for benchmarking
