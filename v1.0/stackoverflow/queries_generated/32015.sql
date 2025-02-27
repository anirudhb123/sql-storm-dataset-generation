WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON p.ParentId = a.Id  -- Join to find Answers linked to Questions
    WHERE 
        a.PostTypeId = 1
),

PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- UpMod votes
        SUM(v.VoteTypeId = 3) AS DownVoteCount,  -- DownMod votes
        AVG(CAST(p.ViewCount AS FLOAT)) AS AvgViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.AvgViewCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 0
        ELSE ub.BadgeCount 
    END AS UserBadgeCount
FROM 
    RecursivePostCTE r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    PostStatistics ps ON r.PostId = ps.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    r.Level = 1  -- Only take top-level posts (Questions)
ORDER BY 
    ps.AvgViewCount DESC
LIMIT 100;  -- Limit to top 100 questions by average view counts
