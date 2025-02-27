-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the total number of posts, the average score of questions,
-- and lists the top users by reputation who have created the most posts.

WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only counting questions
    GROUP BY 
        OwnerUserId
),
AvgScore AS (
    SELECT 
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        UPC.PostCount
    FROM 
        Users U
    JOIN 
        UserPostCounts UPC ON U.Id = UPC.OwnerUserId
    ORDER BY 
        UPC.PostCount DESC
    LIMIT 10  -- Top 10 users by number of questions posted
)

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT AverageScore FROM AvgScore) AS AverageQuestionScore,
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount
FROM 
    TopUsers TU;
