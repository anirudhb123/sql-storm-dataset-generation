WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.Text,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseHistoryRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        TotalScore,
        ReputationRank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    COALESCE(CP.CloseHistoryRank, 'No closes') AS CloseHistoryCount,
    COALESCE(CP.Comment, 'N/A') AS LastCloseComment,
    COALESCE(CP.Text, 'N/A') AS LastCloseDetails
FROM 
    TopUsers T
LEFT JOIN 
    ClosedPosts CP ON T.UserId = CP.PostId
ORDER BY 
    T.ReputationRank ASC, -- Show lower ranked users first
    T.Reputation DESC;
