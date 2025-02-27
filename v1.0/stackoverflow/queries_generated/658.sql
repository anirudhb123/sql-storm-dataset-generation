WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(VoteTypeId = 3), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS Questions,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS Answers,
        COUNT(DISTINCT C.Id) AS Comments,
        COALESCE(SUM(B.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(B.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(B.Class = 3), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
UserScores AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes - Downvotes AS Score,
        Questions,
        Answers,
        Comments,
        GoldBadges + SilverBadges * 0.5 + BronzeBadges * 0.25 AS BadgeScore
    FROM UserActivity
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Score,
        BadgeScore,
        ROW_NUMBER() OVER (ORDER BY (Score + BadgeScore) DESC) AS Rank
    FROM UserScores
)
SELECT 
    U.UserId,
    U.DisplayName,
    COALESCE(U.Score, 0) AS TotalScore,
    COALESCE(U.Rank, 'N/A') AS Rank,
    CASE 
        WHEN U.Rank IS NOT NULL THEN 'Top Contributor'
        ELSE 'Novice Contributor'
    END AS ContributorLevel,
    P.Title,
    COUNT(DISTINCT C.Id) AS CommentsOnPosts,
    MAX(H.CreationDate) AS LastActivityDate
FROM RankedUsers U
LEFT JOIN Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN PostHistory H ON P.Id = H.PostId
WHERE (H.PostHistoryTypeId = 24 OR H.PostHistoryTypeId = 10)
GROUP BY U.UserId, U.DisplayName, U.Score, U.Rank, P.Title
HAVING COUNT(DISTINCT C.Id) > 0
ORDER BY U.Rank;
