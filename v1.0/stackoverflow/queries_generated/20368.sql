WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(uc.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(uc.BadgeNames, 'None') AS UserBadges,
        COALESCE(cc.CloseCount, 0) AS PostCloseCount,
        COALESCE(cc.LastClosedDate, 'Never') AS PostLastClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges uc ON rp.OwnerUserId = uc.UserId
    LEFT JOIN 
        CloseReasonCounts cc ON rp.PostId = cc.PostId
    WHERE 
        rp.PostRank <= 3 -- Top 3 posts per user
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.OwnerDisplayName,
    cd.UserBadgeCount,
    cd.UserBadges,
    cd.PostCloseCount,
    cd.PostLastClosedDate,
    CASE 
        WHEN cd.PostCloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    CombinedData cd
ORDER BY 
    cd.CreationDate DESC
LIMIT 50;

-- Bonus: Count the number of users with and without badges
SELECT 
    COUNT(*) AS TotalUsers,
    COUNT(CASE WHEN BadgeCount > 0 THEN 1 END) AS UsersWithBadges,
    COUNT(CASE WHEN BadgeCount = 0 THEN 1 END) AS UsersWithoutBadges
FROM 
    (SELECT 
        u.Id, 
        COUNT(b.Id) AS BadgeCount
     FROM 
        Users u
     LEFT JOIN 
        Badges b ON u.Id = b.UserId
     GROUP BY 
        u.Id) AS UserBadgeCounts;
