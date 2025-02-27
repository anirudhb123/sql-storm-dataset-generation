WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.GoldBadges, 0) AS Gold,
        COALESCE(UB.SilverBadges, 0) AS Silver,
        COALESCE(UB.BronzeBadges, 0) AS Bronze,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY (U.UpVotes - U.DownVotes) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    WHERE 
        U.Reputation > 0
)
SELECT 
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate,
    RP.Owner,
    TU.DisplayName AS TopUser,
    TU.Gold,
    TU.Silver,
    TU.Bronze
FROM 
    RankedPosts RP
LEFT JOIN 
    TopUsers TU ON RP.Owner = TU.DisplayName
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, TU.NetVotes DESC
UNION ALL
SELECT 
    'Total Badges' AS Title,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS CreationDate,
    NULL AS Owner,
    SUM(Gold) AS TotalGold,
    SUM(Silver) AS TotalSilver,
    SUM(Bronze) AS TotalBronze
FROM 
    TopUsers
GROUP BY 
    1
ORDER BY 
    Score DESC NULLS LAST;
