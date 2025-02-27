WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1
                         WHEN V.VoteTypeId = 3 THEN -1
                         ELSE 0 END), 0) AS VoteScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        COALESCE(P2.Title, 'Not Accepted') AS AcceptedAnswer,
        COALESCE(PAR.PostCount, 0) AS RelatedPostCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts P2 ON P.AcceptedAnswerId = P2.Id
    LEFT JOIN (
        SELECT 
            PL.PostId,
            COUNT(PL.RelatedPostId) AS PostCount
        FROM 
            PostLinks PL
        GROUP BY 
            PL.PostId
    ) PAR ON P.Id = PAR.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
AggregatedResults AS (
    SELECT 
        U.UserId, 
        U.DisplayName,
        U.Reputation,
        SUM(PD.ViewCount) AS TotalViews,
        COUNT(PD.PostId) AS PostCount,
        AVG(PD.Score) AS AveragePostScore
    FROM 
        UserScores U
    JOIN 
        Posts PD ON U.UserId = PD.OwnerUserId
    GROUP BY 
        U.UserId, U.DisplayName, U.Reputation
)
SELECT 
    A.DisplayName,
    A.Reputation,
    A.TotalViews,
    A.PostCount,
    A.AveragePostScore,
    CASE 
        WHEN A.Reputation > 1000 THEN 'High'
        WHEN A.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory,
    COALESCE(PD.AcceptedAnswer, 'N/A') AS AcceptedAnswerTitle,
    PD.ViewCount AS QuestionViewCount
FROM 
    AggregatedResults A
LEFT JOIN 
    PostDetails PD ON A.UserId = PD.OwnerUserId
ORDER BY 
    A.Reputation DESC NULLS LAST, 
    A.TotalViews DESC;
