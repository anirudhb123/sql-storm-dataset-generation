WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation
    FROM 
        UserReputation
    WHERE 
        ReputationRank <= 10
),
QuestionCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS QuestionCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.OwnerUserId
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        COALESCE(QC.QuestionCount, 0) AS QuestionCount
    FROM 
        Posts P
    LEFT JOIN 
        QuestionCounts QC ON P.OwnerUserId = QC.OwnerUserId
    WHERE 
        P.PostTypeId = 1 AND P.Score > 10
)
SELECT 
    TU.DisplayName,
    TQ.Title,
    TQ.Score,
    TQ.CreationDate,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = TQ.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = TQ.PostId AND V.VoteTypeId = 2) AS UpVotes
FROM 
    TopUsers TU
JOIN 
    TopQuestions TQ ON TU.UserId = TQ.OwnerUserId
ORDER BY 
    TQ.Score DESC, TU.Reputation DESC
LIMIT 5
UNION ALL
SELECT 
    'Total' AS DisplayName,
    NULL AS Title,
    SUM(TQ.Score) AS TotalScore,
    NULL AS CreationDate,
    SUM((SELECT COUNT(*) FROM Comments C WHERE C.PostId = TQ.PostId)) AS TotalComments,
    SUM((SELECT COUNT(*) FROM Votes V WHERE V.PostId = TQ.PostId AND V.VoteTypeId = 2)) AS TotalUpVotes
FROM 
    TopQuestions TQ;
