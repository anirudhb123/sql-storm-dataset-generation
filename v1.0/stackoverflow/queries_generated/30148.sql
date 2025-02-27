WITH RECURSIVE UserReputationCTE AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        CAST(0 AS BIGINT) AS Level
    FROM Users U
    WHERE U.Reputation >= 1000  -- Start with users with high reputation

    UNION ALL

    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        Level + 1
    FROM Users U
    INNER JOIN UserReputationCTE CTE ON U.Reputation < CTE.Reputation  -- Get users with lower reputation
    WHERE Level < 5  -- Limit to 5 levels deep to prevent infinite recursion
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(V.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2  -- Count upvotes only
    LEFT JOIN LATERAL unnest(string_to_array(P.Tags, '>')) AS Tag ON true  -- Split tags
    LEFT JOIN Tags T ON T.TagName = TRIM(BOTH '<>' FROM Tag)  -- Join with Tags
    GROUP BY P.Id
    HAVING P.Score > 10 AND COUNT(V.Id) > 5  -- Popular posts with a minimum score and votes
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    PP.PostId,
    PP.Title AS PopularPostTitle,
    PP.CreationDate AS PostCreationDate,
    PP.Score AS PostScore,
    PP.VoteCount,
    UB.BadgeCount,
    UB.BadgeNames
FROM Users U
INNER JOIN UserReputationCTE CTE ON U.Id = CTE.UserId
LEFT JOIN PopularPosts PP ON U.Id = PP.PostId  -- Joining with popular posts
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
WHERE 
    CTE.Level = 0  -- Get top level users
    AND (PP.VoteCount IS NOT NULL OR UB.BadgeCount > 0)  -- At least one popular post or badge
ORDER BY U.Reputation DESC, PP.Score DESC;
