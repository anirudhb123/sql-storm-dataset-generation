
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotes - TotalDownvotes AS NetVotes,
        TotalBadges,
        @rank := @rank + 1 AS Rank
    FROM 
        UserActivity,
        (SELECT @rank := 0) r
    WHERE 
        TotalPosts > 0
    ORDER BY TotalPosts DESC
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.NetVotes,
    U.TotalBadges,
    @voteRank := @voteRank + 1 AS VoteRank,
    @badgeRank := @badgeRank + 1 AS BadgeRank
FROM 
    TopUsers U,
    (SELECT @voteRank := 0, @badgeRank := 0) r
WHERE 
    U.Rank <= 10
ORDER BY 
    U.NetVotes DESC, 
    U.TotalBadges DESC;
