
WITH TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        SUM(IF(P.PostTypeId = 1, 1, 0)) AS QuestionCount,
        SUM(IF(P.PostTypeId = 2, 1, 0)) AS AnswerCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM
        TopUsers
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(*) AS BadgeCount,
        SUM(IF(B.Class = 1, 1, 0)) AS GoldBadgeCount,
        SUM(IF(B.Class = 2, 1, 0)) AS SilverBadgeCount,
        SUM(IF(B.Class = 3, 1, 0)) AS BronzeBadgeCount
    FROM
        Badges B
    JOIN
        Users U ON B.UserId = U.Id
    GROUP BY
        U.Id
)
SELECT
    AU.UserId,
    AU.DisplayName,
    AU.Reputation,
    AU.PostCount,
    AU.TotalScore,
    AU.QuestionCount,
    AU.AnswerCount,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(UB.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM
    ActiveUsers AU
LEFT JOIN
    UserBadges UB ON AU.UserId = UB.UserId
WHERE
    AU.ScoreRank <= 10 OR AU.PostRank <= 10
ORDER BY
    AU.TotalScore DESC, AU.PostCount DESC;
