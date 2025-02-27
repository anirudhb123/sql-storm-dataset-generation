
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        @PostRank := IF(@prevTotalPosts = TotalPosts, @PostRank, @rowNum) AS PostRank,
        @prevTotalPosts := TotalPosts,
        @rowNum := @rowNum + 1 AS rn
    FROM UserActivity
    CROSS JOIN (SELECT @PostRank := 0, @prevTotalPosts := NULL, @rowNum := 1) AS init
    ORDER BY TotalPosts DESC
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        PostRank,
        @UpVoteRank := IF(@prevTotalUpVotes = TotalUpVotes, @UpVoteRank, @rowNum) AS UpVoteRank,
        @prevTotalUpVotes := TotalUpVotes,
        @rowNum := @rowNum + 1 AS rn
    FROM TopUsers
    CROSS JOIN (SELECT @UpVoteRank := 0, @prevTotalUpVotes := NULL, @rowNum := 1) AS init
    ORDER BY TotalUpVotes DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    TotalBadges,
    PostRank,
    UpVoteRank
FROM RankedUsers
WHERE PostRank <= 10 OR UpVoteRank <= 10
ORDER BY PostRank, UpVoteRank;
