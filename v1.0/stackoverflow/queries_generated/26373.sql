WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AverageUserReputation,
        COUNT(DISTINCT U.Id) AS UserCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
QuestionEdits AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6, 10)
    GROUP BY 
        PH.PostId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsContributed
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    ORDER BY 
        PostsContributed DESC
    LIMIT 10
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.AverageUserReputation,
    TS.UserCount,
    QE.EditCount,
    QE.CloseCount,
    TU.DisplayName AS TopUser,
    TU.Reputation AS TopUserReputation
FROM 
    TagStatistics TS
LEFT JOIN 
    QuestionEdits QE ON TS.TagName = (SELECT unnest(string_to_array(P.Tags, '>')) FROM Posts P WHERE P.Id = QE.PostId)
LEFT JOIN 
    TopUsers TU ON TU.Reputation = (SELECT MAX(Reputation) FROM TopUsers)
ORDER BY 
    TS.PostCount DESC
LIMIT 20;
