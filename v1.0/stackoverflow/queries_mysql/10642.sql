
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.Tags
    FROM Posts P
),
TopPostStats AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        PS.Tags,
        @rank_score := IF(@prev_score = PS.Score, @rank_score, @row_number := @row_number + 1) AS ScoreRank,
        @prev_score := PS.Score,
        @rank_view := IF(@prev_view = PS.ViewCount, @rank_view, @row_number_view := @row_number_view + 1) AS ViewRank,
        @prev_view := PS.ViewCount
    FROM PostStats PS,
    (SELECT @rank_score := 0, @prev_score := NULL, @row_number := 0, @rank_view := 0, @prev_view := NULL, @row_number_view := 0) AS init
    ORDER BY PS.Score DESC, PS.ViewCount DESC
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TotalScore,
    US.UpVotes,
    US.DownVotes,
    TPS.Title AS TopScorePostTitle,
    TPS.Score AS TopScorePostScore,
    TPS.ViewCount AS TopViewedPostCount
FROM UserStats US
LEFT JOIN TopPostStats TPS ON US.TotalScore = TPS.Score
WHERE TPS.ScoreRank = 1 OR TPS.ViewRank = 1
ORDER BY US.TotalScore DESC, US.DownVotes ASC;
