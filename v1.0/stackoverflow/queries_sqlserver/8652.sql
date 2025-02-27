
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATEADD(year, -1, GETDATE()) AND 
        P.Score >= 10
), RecentBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Date >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        B.UserId
), ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        R.BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        RecentBadges R ON U.Id = R.UserId
    WHERE 
        U.LastAccessDate >= DATEADD(month, -3, GETDATE())
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate,
    AU.DisplayName AS ActiveUser,
    AU.Reputation,
    AU.BadgeCount
FROM 
    RankedPosts RP
JOIN 
    ActiveUsers AU ON RP.OwnerDisplayName = AU.DisplayName
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
