WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate IS NOT NULL
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryData AS (
    SELECT  
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(phd.LastEditDate, 'No edits') AS LastEdit,
    COALESCE(phd.EditTypes, 'No edits') AS EditReasons,
    ub.BadgeCount,
    CASE 
        WHEN ub.MaxBadgeClass = 1 THEN 'Gold'
        WHEN ub.MaxBadgeClass = 2 THEN 'Silver'
        WHEN ub.MaxBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badges'
    END AS HighestBadge,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score Available'
        ELSE CONCAT(CAST(rp.Score AS varchar(10)), ' points')
    END AS ScoreDisplay
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostHistoryData phd ON rp.PostId = phd.PostId
WHERE 
    rp.UserPostRank = 1 
    AND (up.Reputation > 100 OR up.Location IS NOT NULL)
ORDER BY 
    rp.ViewCount DESC NULLS LAST
LIMIT 50;
This SQL query incorporates CTEs to structure the query in a readable manner while also using window functions, aggregate functions, and string manipulations to extract and present useful metrics about posts in the StackOverflow schema. The final results give insights into users and their posts, rankings, edits, and badges, handling NULL logic within various expressions.
