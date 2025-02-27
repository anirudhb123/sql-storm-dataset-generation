
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT ctr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ctr ON ph.Comment = CAST(ctr.Id AS CHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.PostCount,
    ru.TotalViews,
    ub.BadgeNames,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    pcr.CloseReasons
FROM 
    RankedUsers ru
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId
LEFT JOIN 
    PostCloseReasons pcr ON p.Id = pcr.PostId
WHERE 
    (ru.PostCount > 5 OR ub.GoldCount > 0)
    AND (p.LastActivityDate IS NULL OR p.LastActivityDate > NOW() - INTERVAL 30 DAY)
ORDER BY 
    ru.ViewRank,
    ru.PostCount DESC;
