WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(A.Id) AS AnswerCount,
        MAX(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HasComments,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    JOIN 
        Posts P ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.ViewCount,
    R.Score,
    R.AnswerCount,
    R.HasComments,
    U.UserId,
    U.Reputation AS UserReputation,
    U.QuestionCount,
    U.AvgScore,
    CASE 
        WHEN U.Reputation IS NULL THEN 'No Reputation' 
        ELSE 
            CASE 
                WHEN U.Reputation >= 1000 THEN 'High Reputation' 
                WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation' 
                ELSE 'Low Reputation' 
            END 
    END AS ReputationLevel
FROM 
    RecursivePostStats R
LEFT JOIN 
    UserReputation U ON U.UserId = R.CreationDate
WHERE 
    R.ViewCount > 10
    AND R.AnswerCount >= 1
    AND R.UserPostRank <= 5
ORDER BY 
    R.Score DESC, R.ViewCount DESC
LIMIT 50;

-- Additional information on top performing posts based on votes
SELECT 
    P.Id AS PostId,
    P.Title,
    COUNT(V.Id) AS VoteCount
FROM 
    Posts P
LEFT JOIN 
    Votes V ON V.PostId = P.Id
WHERE 
    P.PostTypeId = 1  -- Only questions
GROUP BY 
    P.Id, P.Title
HAVING 
    COUNT(V.Id) > 5
ORDER BY 
    VoteCount DESC
LIMIT 10;

-- Combining results for final performance benchmark
WITH FinalBenchmark AS (
    SELECT 
        R.*, 
        V.VoteCount
    FROM 
        RecursivePostStats R 
    LEFT JOIN 
        (SELECT 
            P.Id AS PostId,
            COUNT(V.Id) AS VoteCount
         FROM 
            Posts P 
         LEFT JOIN 
            Votes V ON V.PostId = P.Id
         WHERE 
            P.PostTypeId = 1
         GROUP BY 
            P.Id
         HAVING 
            COUNT(V.Id) > 5) V ON V.PostId = R.PostId
)
SELECT * 
FROM 
    FinalBenchmark
WHERE 
    UserReputation IS NOT NULL 
ORDER BY 
    UserReputation DESC, VoteCount DESC
LIMIT 100;
