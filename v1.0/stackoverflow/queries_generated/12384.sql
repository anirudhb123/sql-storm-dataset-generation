-- Performance Benchmarking SQL Query

-- Measure the time taken to retrieve user information along with their badges and the latest posts.
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Date AS BadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
)

SELECT 
    ub.UserId,
    ub.DisplayName,
    STRING_AGG(ub.BadgeName, ', ') AS Badges,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore
FROM 
    UserBadges ub
LEFT JOIN 
    RankedPosts rp ON ub.UserId = rp.OwnerUserId AND rp.rn = 1  -- Get latest post per user
GROUP BY 
    ub.UserId, ub.DisplayName, rp.PostId, rp.Title, rp.CreationDate, rp.Score
ORDER BY 
    ub.DisplayName;
