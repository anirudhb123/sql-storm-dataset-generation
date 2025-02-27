WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
TopPosts AS (
    SELECT 
        P.Title,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC NULLS LAST) AS PostRank
    FROM Posts P 
    WHERE P.Score IS NOT NULL
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.ReputationRank,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    TP.Title AS TopPostTitle
FROM RankedUsers U
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
LEFT JOIN TopPosts TP ON U.UserId = TP.OwnerUserId AND TP.PostRank = 1
WHERE U.ReputationRank <= 10
ORDER BY U.Reputation DESC,
         BadgeCount DESC,
         TotalViews DESC;

-- Edge cases and obscure predicates
WITH RecursivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        1 AS Level,
        ARRAY[P.Id] AS Path
    FROM Posts P
    WHERE P.ParentId IS NULL
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        RP.Level + 1,
        RP.Path || P.Id
    FROM Posts P
    JOIN RecursivePosts RP ON P.ParentId = RP.Id
    WHERE NOT P.Id = ANY(RP.Path)  -- Prevent cycles
),
PostHierarchy AS (
    SELECT 
        RP.Id,
        RP.Title,
        RP.Level,
        COUNT(C) AS CommentCount,
        MAX(PL.CreationDate) AS LatestLinkDate
    FROM RecursivePosts RP
    LEFT JOIN Comments C ON RP.Id = C.PostId
    LEFT JOIN PostLinks PL ON RP.Id = PL.PostId
    GROUP BY RP.Id, RP.Title, RP.Level
)
SELECT 
    PH.Title,
    PH.Level,
    PH.CommentCount,
    PH.LatestLinkDate,
    CASE 
        WHEN PH.CommentCount > 0 THEN 'Comments exist'
        ELSE 'No comments'
    END AS CommentStatus
FROM PostHierarchy PH
WHERE PH.Level > (SELECT AVG(Level) FROM PostHierarchy)  -- Filter on hierarchy
ORDER BY PH.Level, PH.CommentCount DESC;

-- Evaluating NULL conditions and string patterns
SELECT 
    P.Id,
    P.Title,
    COALESCE(P.Body, 'No body available') AS PostBody,
    CASE 
        WHEN P.Tags IS NULL OR P.Tags = '' THEN 'Unlabeled'
        ELSE regexp_replace(P.Tags, '[<>]', '', 'g') -- Removing angle brackets from tags
    END AS CleanedTags
FROM Posts P
WHERE (P.Body IS NULL OR P.Body LIKE '%example%')
  AND (P.CreationDate >= '2023-01-01' OR P.ViewCount IS NULL)  -- NULL logic case
ORDER BY P.CreationDate DESC 
LIMIT 50;
