WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score >= 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        AVG(DATEDIFF(MINUTE, P.CreationDate, CONVERT(DATETIME, GETDATE()))) AS AveragePostAgeMinutes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        PositiveScoreCount,
        NegativeScoreCount,
        AveragePostAgeMinutes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.PositiveScoreCount,
    TU.NegativeScoreCount,
    TU.AveragePostAgeMinutes,
    P.Title AS MostRecentPostTitle,
    P.CreationDate AS MostRecentPostDate,
    (SELECT 
        STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM 
        Posts P2 
     JOIN 
        STRING_SPLIT(P2.Tags, '>') AS T ON P2.Id = P.Id 
     WHERE 
        P2.OwnerUserId = TU.UserId) AS AssociatedTags
FROM 
    TopUsers TU
LEFT JOIN 
    (SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
     FROM 
        Posts P) P ON TU.UserId = P.OwnerUserId AND P.RecentPostRank = 1
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.Reputation DESC;

This SQL query performs the following operations:

1. **UserStatistics CTE** computes various metrics for users, including total posts, question and answer counts, positive and negative score counts, and the average age of their posts.
2. **TopUsers CTE** ranks users based on reputation and includes their computed statistics.
3. The final SELECT statement gathers the top 10 users (by ranking), their most recent post, along with associated tags from the most recent post, formatted in a comma-separated string. 

This query can be used to benchmark complex string processing, aggregation, and ranking functions within SQL.
