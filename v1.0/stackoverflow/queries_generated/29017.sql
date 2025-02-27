WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AverageReputation,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS Contributors
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.TagName
), 
CloseReasonStatistics AS (
    SELECT
        PH.Comment AS CloseReason,
        COUNT(DISTINCT P.Id) AS ClosedPostCount,
        AVG(EXTRACT(EPOCH FROM (P.LastActivityDate - P.CreationDate))) AS AvgPostLifetime
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen events
    GROUP BY 
        PH.Comment
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.AverageReputation,
    T.Contributors,
    CR.CloseReason,
    CR.ClosedPostCount,
    CR.AvgPostLifetime
FROM 
    TagStatistics T
LEFT JOIN 
    CloseReasonStatistics CR ON TRUE -- Cross join to analyze tags with close reasons
ORDER BY 
    T.PostCount DESC, CR.ClosedPostCount DESC;
