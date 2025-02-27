WITH RecursivePostHierarchy AS (
    -- CTE to find all answers related to questions and their acceptance status
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        A.Id AS PostId,
        A.Title,
        A.OwnerUserId,
        A.AcceptedAnswerId,
        A.CreationDate,
        A.ViewCount,
        A.Score,
        R.Level + 1
    FROM 
        Posts A
    INNER JOIN 
        RecursivePostHierarchy R ON A.ParentId = R.PostId 
    WHERE 
        A.PostTypeId = 2  -- Answers
),
UserReputation AS (
    -- CTE to calculate total votes and badges per user
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostScoreAnalysis AS (
    -- CTE to analyze post scores and user contributions
    SELECT 
        RPH.PostId,
        RPH.Title,
        RPH.Score,
        RPH.OwnerUserId,
        UR.DisplayName,
        UR.Reputation,
        UR.TotalUpVotes,
        UR.TotalDownVotes,
        RPH.CreationDate,
        RPH.Level,
        CASE 
            WHEN RPH.Score > 10 THEN 'High Scorer' 
            WHEN RPH.Score BETWEEN 5 AND 10 THEN 'Moderate Scorer' 
            ELSE 'Low Scorer' 
        END AS ScoreCategory
    FROM 
        RecursivePostHierarchy RPH
    JOIN 
        UserReputation UR ON RPH.OwnerUserId = UR.UserId
)
SELECT 
    PSA.PostId,
    PSA.Title,
    PSA.Score,
    PSA.ScoreCategory,
    PSA.DisplayName,
    PSA.Reputation,
    PSA.TotalUpVotes,
    PSA.TotalDownVotes,
    DATE_PART('year', CURRENT_TIMESTAMP - PSA.CreationDate) AS YearsSinceCreation,
    ROW_NUMBER() OVER (PARTITION BY PSA.OwnerUserId ORDER BY PSA.Score DESC) AS PostRank
FROM 
    PostScoreAnalysis PSA
WHERE 
    PSA.Reputation >= 1000  -- Only include users with significant reputation
ORDER BY 
    PSA.Score DESC, PSA.YearsSinceCreation ASC;
