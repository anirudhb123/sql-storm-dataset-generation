WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(V.Score, 0)) AS TotalVotes,
        AVG(V.Score) FILTER (WHERE V.Score IS NOT NULL AND V.Score > 0) AS AverageUpVotes,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) DESC) AS MostQuestionsRank,
        P.Title,
        P.CreationDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    GROUP BY 
        P.OwnerUserId, P.Title, P.CreationDate
),
ClosedPosts AS (
    SELECT 
        H.PostId,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN H.PostHistoryTypeId = 10 THEN H.CreationDate END) AS LastClosedDate
    FROM 
        PostHistory H
    WHERE 
        H.PostHistoryTypeId = 10
    GROUP BY 
        H.PostId
)
SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    UB.TotalBadges,
    UB.BadgeNames,
    PS.PostCount,
    PS.TotalVotes,
    PS.AverageUpVotes,
    PS.MostQuestionsRank,
    COALESCE(CP.CloseCount, 0) AS TotalClosedPosts,
    COALESCE(CP.LastClosedDate, 'Never Closed') AS LastClosedPostDate
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON PS.OwnerUserId = CP.PostId
WHERE 
    U.Reputation > 1000 
    AND (UB.TotalBadges IS NULL OR UB.TotalBadges > 1)
ORDER BY 
    U.Reputation DESC,
    PostCount DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

-- This query aims to benchmark performance by:
-- 1. Using multiple CTEs for organizing complex aggregations.
-- 2. Incorporating various features, including string aggregation, ranking, 
--    conditional aggregation, and outer joins.
-- 3. Employing filtering and ranking to focus on high-reputation users with 
--    notable activity, while also showcasing NULL handling with COALESCE.
-- 4. Utilizing complex criteria in the WHERE clause to filter the dataset further, 
--    emphasizing users with specific activity and badge requirements.
