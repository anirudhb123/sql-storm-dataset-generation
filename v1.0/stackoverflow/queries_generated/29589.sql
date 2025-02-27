WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY T.TagName
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        COUNT(DISTINCT V.Id) AS VotesCast,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON C.UserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagStats
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.AverageScore,
    U.DisplayName AS TopUser,
    U.PostsCreated,
    U.CommentsMade,
    U.VotesCast,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges
FROM TopTags T
JOIN UserEngagement U ON U.PostsCreated = (SELECT MAX(PostsCreated) FROM UserEngagement)
WHERE T.Rank <= 10
ORDER BY T.PostCount DESC;
