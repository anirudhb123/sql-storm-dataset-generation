WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    Rank,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
