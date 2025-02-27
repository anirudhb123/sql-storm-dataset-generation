
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @rank := @rank + 1) AS ScoreRank,
        @prevScore := TotalScore,
        @PostRank := IF(@prevPosts = TotalPosts, @PostRank, @rankPosts := @rankPosts + 1) AS PostRank,
        @prevPosts := TotalPosts
    FROM
        UserStats,
        (SELECT @ScoreRank := 0, @PostRank := 0, @prevScore := NULL, @prevPosts := NULL, @rank := 0, @rankPosts := 0) r
    ORDER BY
        TotalScore DESC, TotalPosts DESC
)
SELECT
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalScore,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalBadges,
    U.ScoreRank,
    U.PostRank
FROM
    TopUsers U
WHERE
    U.ScoreRank <= 10 OR U.PostRank <= 10
ORDER BY
    U.ScoreRank, U.PostRank;
