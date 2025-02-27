
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
        AND p.ViewCount > 100
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    RP.Id AS PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RB.BadgeNames,
    RB.BadgeCount
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges RB ON RP.OwnerUserId = RB.UserId
WHERE 
    RP.PostRank = 1
    AND (RB.BadgeCount IS NULL OR RB.BadgeCount > 5)
ORDER BY 
    RP.Score DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
