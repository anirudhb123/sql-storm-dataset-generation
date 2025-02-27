WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(U.LastAccessDate) AS LastActive
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostActivityStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
VoteDetails AS (
    SELECT 
        V.UserId,
        P.OwnerUserId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.PostId) AS UniquePostsVoted
    FROM Votes V
    JOIN Posts P ON V.PostId = P.Id
    GROUP BY V.UserId, P.OwnerUserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PA.PostCount, 0) AS PostCount,
    COALESCE(PA.QuestionCount, 0) AS QuestionCount,
    COALESCE(PA.AnswerCount, 0) AS AnswerCount,
    COALESCE(PA.TotalViews, 0) AS TotalViews,
    COALESCE(PA.AverageScore, 0) AS AverageScore,
    COALESCE(VD.TotalVotes, 0) AS TotalVotes,
    COALESCE(VD.UpVotes, 0) AS UpVotes,
    COALESCE(VD.DownVotes, 0) AS DownVotes,
    COALESCE(VD.UniquePostsVoted, 0) AS UniquePostsVoted,
    CASE 
        WHEN UB.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus,
    CASE 
        WHEN PA.PostCount < 10 THEN 'Newbie'
        WHEN PA.PostCount BETWEEN 10 AND 50 THEN 'Established'
        ELSE 'Veteran'
    END AS UserLevel,
    NULLIF(U.Location, '') AS UserLocation -- handling NULL logic
FROM Users U
LEFT JOIN UserBadgeStats UB ON U.Id = UB.UserId
LEFT JOIN PostActivityStats PA ON U.Id = PA.OwnerUserId
LEFT JOIN VoteDetails VD ON U.Id = VD.UserId
WHERE U.Reputation > 1000 -- filtering out users with low reputation
ORDER BY U.Reputation DESC, BadgeCount DESC
LIMIT 50;

-- Testing the edge cases: 
-- SELECT some cases of NULL values in different fields
WITH NullCaseTest AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Posts.Id AS PostId,
        Posts.Title,
        CASE 
            WHEN Posts.OwnerUserId IS NULL THEN 'Owner UserId is NULL'
            ELSE 'Owner UserId is present'
        END AS PostOwnerCheck,
        (SELECT COUNT(*) 
         FROM Comments C 
         WHERE C.PostId = Posts.Id) AS CommentCount
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    WHERE Users.Reputation > 1000
    ORDER BY Users.Id
)
SELECT * FROM NullCaseTest
WHERE CommentCount IS NULL; -- looking for posts with no comments
