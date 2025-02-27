
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes
    FROM Users U
    WHERE U.Reputation > 1000
), PostDetails AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
), UserPostActivity AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        PS.PostCount,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.AverageScore,
        PS.TotalViews,
        US.NetVotes,
        @rank := IF(@prevTotalViews = PS.TotalViews, @rank, @rank + 1) AS RankByViews,
        @prevTotalViews := PS.TotalViews
    FROM UserScores US
    JOIN PostDetails PS ON US.UserId = PS.OwnerUserId
    CROSS JOIN (SELECT @rank := 0, @prevTotalViews := NULL) r
    ORDER BY PS.TotalViews DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    AverageScore,
    TotalViews,
    NetVotes,
    RankByViews
FROM UserPostActivity
WHERE RankByViews <= 10
ORDER BY RankByViews;
