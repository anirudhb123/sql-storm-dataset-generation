
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN P.LastActivityDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 MONTH) THEN 1 ELSE 0 END) AS RecentPostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
), BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
), CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.Views,
        US.UpVotes,
        US.DownVotes,
        US.PostCount,
        US.QuestionCount,
        US.AnswerCount,
        US.WikiCount,
        US.RecentPostCount,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
    FROM UserStats US
    LEFT JOIN BadgeStats BS ON US.UserId = BS.UserId
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        RecentPostCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @rank := @rank + 1 AS Rank
    FROM CombinedStats, (SELECT @rank := 0) r
    ORDER BY Reputation DESC
)
SELECT *
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
