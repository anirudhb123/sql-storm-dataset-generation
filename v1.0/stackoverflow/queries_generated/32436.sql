WITH RecursivePostDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.OwnerUserId, 
        P.ParentId, 
        P.CreationDate,
        1 AS Level,
        CAST(P.Title AS varchar(400)) AS Path
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT 
        P2.Id AS PostId, 
        P2.Title, 
        P2.OwnerUserId, 
        P2.ParentId, 
        P2.CreationDate,
        Level + 1,
        CAST(RPD.Path + ' -> ' + P2.Title AS varchar(400)) AS Path
    FROM Posts P2
    INNER JOIN RecursivePostDetails RPD ON P2.ParentId = RPD.PostId
)
SELECT 
    U.DisplayName AS UserName, 
    COUNT(P.Id) AS AnswerCount,
    SUM(V.CreationDate IS NOT NULL AND V.VoteTypeId = 2) AS UpVotes,
    SUM(V.CreationDate IS NOT NULL AND V.VoteTypeId = 3) AS DownVotes,
    MAX(CASE WHEN (P.ClosedDate IS NOT NULL AND PH.PostHistoryTypeId = 10) THEN 1 ELSE 0 END) AS ClosedQuestion,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    RD.Path AS AnswerPath
FROM RecursivePostDetails RD
JOIN Posts P ON RD.PostId = P.AcceptedAnswerId 
JOIN Users U ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON V.PostId = P.Id
LEFT JOIN PostHistory PH ON PH.PostId = P.Id AND PH.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = P.Id)
LEFT JOIN Tags T ON T.Id IN (SELECT unnest(string_to_array(P.Tags, '<>'))::int)
WHERE RD.Level = 1  -- Only interested in top level questions
GROUP BY U.DisplayName, RD.Path
HAVING COUNT(P.Id) > 10
ORDER BY UserName;
