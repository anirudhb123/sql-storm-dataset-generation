-- Performance benchmarking query to analyze posts, users, and votes

WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Only consider posts created in 2023
    GROUP BY 
        p.Id, u.Reputation
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerReputation,
    ps.VoteCount,
    us.DisplayName,
    us.Reputation AS UserReputation,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.UpVotes,
    us.DownVotes
FROM 
    PostStatistics ps
JOIN 
    UserStatistics us ON ps.OwnerReputation = us.Reputation
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
