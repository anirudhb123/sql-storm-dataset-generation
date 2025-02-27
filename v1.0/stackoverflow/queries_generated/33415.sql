WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        A.Id AS PostId,
        A.Title,
        A.OwnerUserId,
        A.CreationDate,
        A.Score,
        A.AnswerCount,
        R.Level + 1
    FROM 
        Posts A
    INNER JOIN 
        RecursiveCTE R ON A.ParentId = R.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(SUM(CASE WHEN PH.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS PostHistoryCount,
    COUNT(DISTINCT R.PostId) AS QuestionCount,
    COUNT(DISTINCT CASE WHEN R.Level > 0 THEN R.PostId END) AS AnswerCount,
    AVG(R.Score) AS AverageScore,
    MAX(R.CreationDate) AS LastActivityDate,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    RecursiveCTE R ON P.Id = R.PostId
LEFT JOIN 
    Tags T ON T.Id = ANY(string_to_array(P.Tags, ', ')::int[])  -- Assuming Tags are stored in an array-like format
WHERE 
    U.Reputation > 1000  -- Filter users with reputation above 1000
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostHistoryCount DESC, AnswerCount DESC, AverageScore DESC
LIMIT 50;
