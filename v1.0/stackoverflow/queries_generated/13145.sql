-- Performance Benchmarking Query for StackOverflow Schema

-- This query aims to benchmark the performance of joining multiple tables 
-- and retrieving key metrics related to posts, users, and their activities.

WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    COALESCE(ub.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    PostSummary ps
LEFT JOIN 
    UserBadges ub ON ps.OwnerDisplayName = ub.UserId
ORDER BY 
    ps.PostCreationDate DESC
LIMIT 100;
