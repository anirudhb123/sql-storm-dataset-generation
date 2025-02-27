WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0 -- Only Questions with a positive score
),
TopUserPosts AS (
    SELECT 
        r.OwnerUserId,
        COUNT(r.PostId) AS PostCount,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViews
    FROM 
        RankedPosts r
    WHERE 
        r.RowNum <= 5 -- Top 5 posts per user
    GROUP BY 
        r.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        t.PostCount,
        t.TotalScore,
        t.TotalViews
    FROM 
        Users u
    JOIN 
        TopUserPosts t ON u.Id = t.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalScore,
    u.TotalViews,
    COALESCE(b.Class, 'No Badge') AS BadgeClass,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    UserReputation u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
WHERE 
    u.Reputation > 1000 -- Only users with reputation greater than 1000
ORDER BY 
    u.Reputation DESC, 
    u.TotalScore DESC
LIMIT 10; -- Limit to top 10 users by reputation and score
