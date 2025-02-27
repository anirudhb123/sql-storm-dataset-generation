WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedQuestions
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(P.ACceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        PS.*,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM PS.CreationDate) ORDER BY PS.Score DESC) AS ScoreRank
    FROM PostStatistics PS
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.ClosedQuestions,
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.Score,
    PP.ViewCount,
    PP.AcceptedAnswerId,
    PP.Upvotes,
    PP.Downvotes,
    PP.CommentCount,
    PP.RowNum,
    PP.ScoreRank,
    CASE 
        WHEN PP.ScoreRank = 1 THEN 'Top Post'
        WHEN PP.ScoreRank <= 5 THEN 'Top 5 Post'
        ELSE 'Other Post'
    END AS PostRankCategory
FROM UserActivity UA
JOIN RankedPosts PP ON UA.TotalPosts > 0
    AND PP.UserId = UA.UserId
WHERE PP.ScoreRank <= 10
ORDER BY UA.Reputation DESC, PP.Score DESC, UA.DisplayName;

-- Include a NULL logic scenario in case there are users without posts
SELECT DISTINCT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    COALESCE(UA.TotalPosts, 0) AS TotalPosts,
    COALESCE(UA.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(UA.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(UA.ClosedQuestions, 0) AS ClosedQuestions,
    CASE
        WHEN UA.TotalPosts IS NULL THEN 'No Posts'
        ELSE 'Has Posts'
    END AS PostStatus
FROM UserActivity UA
WHERE UA.Reputation > 1000
ORDER BY UA.Reputation DESC;

-- Utilizing an outer join to capture users without posts
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UP.TotalPosts, 0) AS TotalPosts
FROM Users U
LEFT JOIN (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts
    FROM Posts
    GROUP BY OwnerUserId
) UP ON U.Id = UP.OwnerUserId
WHERE U.Reputation > 500
ORDER BY TotalPosts DESC;

-- Complex predicates and string expressions involving post titles
SELECT 
    P.Id,
    P.Title,
    P.Body,
    CASE 
        WHEN POSITION('SQL' IN P.Title) > 0 THEN 'Related to SQL'
        ELSE 'Not Related' 
    END AS TitleRelevance
FROM Posts P
WHERE P.Body IS NOT NULL
AND LENGTH(P.Body) > 100
AND LEFT(P.Title, 3) = 'How';
