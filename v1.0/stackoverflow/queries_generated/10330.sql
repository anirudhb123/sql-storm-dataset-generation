-- Performance benchmarking SQL query for the Stack Overflow schema

-- This query will retrieve a summary of post performance metrics including counts and averages for posts and votes,
-- as well as user-related data to analyze performance

WITH PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        AVG(v.CreationDate) AS AverageVoteDate
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, u.Reputation, u.DisplayName
),
UserMetrics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)

SELECT
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.OwnerDisplayName,
    pm.OwnerReputation,
    pm.VoteCount,
    pm.AverageVoteDate,
    um.UserId AS PostOwnerUserId,
    um.TotalPosts,
    um.TotalBadges,
    um.TotalUpVotes,
    um.TotalDownVotes
FROM
    PostMetrics pm
JOIN
    UserMetrics um ON pm.OwnerReputation = um.TotalUpVotes -- Example join condition, can be adjusted as needed
ORDER BY
    pm.Score DESC, pm.ViewCount DESC;
