
WITH UserStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE NULL END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE NULL END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 ELSE NULL END) AS DeleteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
TopUsers AS (
    SELECT 
        US.Id,
        US.DisplayName,
        US.Reputation,
        @row_number := IF(@prev_reputation = US.Reputation, @row_number + 1, 1) AS ReputationRank,
        @prev_reputation := US.Reputation
    FROM 
        UserStats US, (SELECT @row_number := 0, @prev_reputation := NULL) AS init
    WHERE 
        US.Reputation > 1000
    ORDER BY 
        US.Reputation DESC
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    P.Title,
    P.CreationDate,
    COALESCE(PHS.CloseCount, 0) AS CloseCount,
    COALESCE(PHS.ReopenCount, 0) AS ReopenCount,
    COALESCE(PHS.DeleteCount, 0) AS DeleteCount,
    US.TotalBounty,
    @post_rank := IF(@prev_rank = TU.ReputationRank, @post_rank + 1, 1) AS PostRank,
    @prev_rank := TU.ReputationRank
FROM 
    TopUsers TU, (SELECT @post_rank := 0, @prev_rank := NULL) AS init
JOIN 
    Posts P ON TU.Id = P.OwnerUserId
LEFT JOIN 
    PostHistorySummary PHS ON P.Id = PHS.PostId
JOIN 
    UserStats US ON TU.Id = US.Id
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL 1 YEAR 
    AND (P.Title LIKE '%SQL%' OR P.Tags LIKE '%SQL%')
ORDER BY 
    TU.Reputation DESC, 
    P.CreationDate DESC;
