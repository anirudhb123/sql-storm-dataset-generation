-- Performance Benchmarking SQL Query for Stack Overflow Schema

-- Measure the execution time for retrieving users with their posts and corresponding comments and badges
WITH UserPostInfo AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    GROUP BY 
        u.Id, p.Id
),
UserBadgeInfo AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

-- Final selection with join to get entire user post info along with badge count
SELECT 
    up.UserId,
    up.UserName,
    up.PostId,
    up.PostTitle,
    up.PostCreationDate,
    up.CommentCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    UserPostInfo up
LEFT JOIN 
    UserBadgeInfo ub ON up.UserId = ub.UserId
ORDER BY 
    up.UserId, up.PostCreationDate DESC;
