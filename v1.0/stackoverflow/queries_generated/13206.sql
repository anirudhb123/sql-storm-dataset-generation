-- Performance Benchmarking Query for Stack Overflow Schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        U.CreationDate,
        COUNT(B.Id) AS BadgeCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViewCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        BadgeCount, 
        UpVotes, 
        DownVotes, 
        QuestionCount, 
        AnswerCount, 
        TotalViewCount, 
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Ranking
    FROM 
        UserStats
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    BadgeCount, 
    UpVotes, 
    DownVotes, 
    QuestionCount, 
    AnswerCount, 
    TotalViewCount, 
    AverageScore
FROM 
    TopUsers
WHERE 
    Ranking <= 10; -- Top 10 users by reputation
