-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves various metrics to analyze performance across Posts, Users, Comments, and Votes

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
        COALESCE(AVG(c.Score), 0) AS AverageCommentScore,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, u.Reputation, u.DisplayName
),

UserMetrics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
)

SELECT
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.OwnerReputation,
    pm.OwnerDisplayName,
    pm.AverageCommentScore,
    pm.VoteCount,
    um.UserId,
    um.TotalPosts,
    um.TotalComments,
    um.TotalBadges
FROM
    PostMetrics pm
JOIN
    UserMetrics um ON pm.OwnerReputation = um.Reputation
ORDER BY
    pm.Score DESC, pm.ViewCount DESC;
