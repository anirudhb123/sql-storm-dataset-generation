WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' 
        AND P.ViewCount > 100 
        AND P.Score >= 0
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate,
    TU.DisplayName,
    TU.PostCount,
    TU.TotalScore,
    UB.BadgeNames
FROM 
    RankedPosts RP
LEFT JOIN 
    TopUsers TU ON RP.OwnerUserId = TU.UserId
LEFT JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;

-- Additional information for benchmarking:
-- This query combines several CTEs to analyze top posts in the last year,
-- ranks them by score, and associates them with users who have a significant
-- number of popular posts. It also retrieves user badge information 
-- and limits the output to the top 5 posts per post type, ordering the final results 
-- by score and view count.
