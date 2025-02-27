WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgPostScore,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgPostScore,
        TotalComments,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY TotalPosts DESC) AS PostRank,
        COUNT(*) OVER () AS TotalUsers
    FROM UserPostStats
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgPostScore,
        TotalComments
    FROM RankedUsers
    WHERE PostRank <= 10
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AvgPostScore,
    TC.CommentCount
FROM TopUsers TU
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY P.OwnerUserId
) TC ON TU.UserId = TC.OwnerUserId
WHERE TU.TotalPosts > 5 -- Only include users with more than 5 posts
ORDER BY TU.Reputation DESC, TU.TotalPosts DESC;

WITH RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY V.UserId
),
PopularPosts AS (
    SELECT 
        P.Title,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes
    FROM Posts P
    JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY P.Title
    HAVING SUM(V.VoteTypeId = 2) > 10 -- Only consider posts with more than 10 upvotes
)

SELECT 
    PP.Title,
    PP.TotalUpVotes,
    PP.TotalDownVotes,
    CASE 
        WHEN PP.TotalUpVotes > PP.TotalDownVotes THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityIndicator,
    RU.DisplayName,
    RV.TotalVotes
FROM PopularPosts PP
JOIN RecentVotes RV ON PP.Title = RV.UserId 
LEFT JOIN Users RU ON RV.UserId = RU.Id
ORDER BY PP.TotalUpVotes DESC;

