WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
AsciiBadges AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS BadgeList
    FROM Badges
    GROUP BY UserId
),
PostsWithTagCounts AS (
    SELECT 
        P.Id,
        P.OwnerUserId,
        P.Title,
        COALESCE(LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '<', '')), 0) AS TagCount
    FROM Posts P
),
HighScoringPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    WHERE P.Score IS NOT NULL AND P.Score > 0
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END, 0)) AS TotalUpvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownvotes,
        MAX(V.CreationDate) AS LastVoteDate
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
)

SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.ReputationRank,
    AB.BadgeList,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(COALESCE(PW.TagCount, 0)) AS TotalTagsUsed,
    SUM(COALESCE(HP.Score, 0)) AS TotalScore,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    MAX(UA.LastVoteDate) AS LastVoteTimestamp
FROM RankedUsers RU
LEFT JOIN AsciiBadges AB ON RU.Id = AB.UserId
LEFT JOIN PostsWithTagCounts PW ON RU.Id = PW.OwnerUserId
LEFT JOIN HighScoringPosts HP ON RU.Id = HP.OwnerUserId
LEFT JOIN UserActivity UA ON RU.Id = UA.UserId
WHERE 
    RU.ReputationRank <= 100 AND 
    (UNIX_TIMESTAMP() - UNIX_TIMESTAMP(RU.CreationDate)) < 31536000 AND -- Users created within the last year
    (UA.TotalUpvotes - UA.TotalDownvotes) > 10 -- Net positive votes
GROUP BY 
    RU.Id, RU.DisplayName, RU.Reputation, RU.ReputationRank, AB.BadgeList
HAVING 
    COUNT(DISTINCT P.Id) >= 5 -- Users with at least 5 posts
ORDER BY 
    RU.Reputation DESC, 
    TotalScore DESC;

