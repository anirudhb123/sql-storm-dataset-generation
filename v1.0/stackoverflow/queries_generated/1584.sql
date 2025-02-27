WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostReputation AS (
    SELECT 
        P.OwnerUserId,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    GROUP BY P.OwnerUserId
),
UserDetails AS (
    SELECT 
        U.DisplayName,
        COALESCE(UR.Reputation, 0) AS Reputation,
        COALESCE(PR.TotalBounty, 0) AS TotalBounty,
        COALESCE(PR.TotalPosts, 0) AS TotalPosts,
        COALESCE(PR.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PR.TotalAnswers, 0) AS TotalAnswers
    FROM Users U
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostReputation PR ON U.Id = PR.OwnerUserId
)
SELECT 
    UD.DisplayName,
    UD.Reputation,
    UD.TotalBounty,
    UD.TotalPosts,
    UD.TotalQuestions,
    UD.TotalAnswers,
    CASE 
        WHEN UD.Reputation > 1000 THEN 'High Reputation'
        WHEN UD.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserDetails UD
WHERE UD.TotalPosts > 0
ORDER BY UD.Reputation DESC
LIMIT 10;

-- Including a check for users who have never posted a question or an answer

SELECT 
    U.DisplayName AS IgnoredUser,
    A.UserId AS IgnoredUserId,
    NULLIF(A.Reputation, 0) AS Reputation
FROM Users U
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(V.BountyAmount) AS TotalBounty,
        COALESCE(MAX(V.UserId), -1) AS LastVoter
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
) A ON U.Id = A.OwnerUserId
WHERE A.Questions = 0 
    AND A.Answers = 0
ORDER BY U.Reputation DESC
LIMIT 5;
