WITH RecursivePostHistory AS (
    SELECT 
        Ph.Id,
        Ph.PostId,
        Ph.UserDisplayName,
        Ph.CreationDate,
        Ph.Comment,
        Ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen events
    UNION ALL
    SELECT 
        Ph.Id,
        Ph.PostId,
        Ph.UserDisplayName,
        Ph.CreationDate,
        Ph.Comment,
        Ph.PostHistoryTypeId,
        Level + 1
    FROM 
        PostHistory Ph
    INNER JOIN 
        RecursivePostHistory RPh ON RPh.PostId = Ph.PostId
    WHERE 
        Ph.CreationDate < RPh.CreationDate -- Keep going back in time
)
SELECT 
    P.Title,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    AVG(U.Reputation) AS AvgReputation,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    PH.Comment AS LastCloseComment,
    RPh.UserDisplayName AS CommentingUser,
    RPh.CreationDate AS CommentDate,
    RPh.Level
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Tags T ON T.Id = ANY (string_to_array(P.Tags, ',')::int[])  -- assuming Tags is an array of IDs
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10  -- Last close action
LEFT JOIN 
    RecursivePostHistory RPh ON P.Id = RPh.PostId
WHERE 
    P.CreationDate > NOW() - INTERVAL '1 year' 
GROUP BY 
    P.Title, PH.Comment, RPh.UserDisplayName, RPh.CreationDate, RPh.Level
ORDER BY 
    P.Title ASC, RPh.CreationDate DESC
LIMIT 100;

-- Adding additional filtering criteria post query
HAVING 
    COUNT(V.Id) > 10  -- Only include posts with more than 10 votes.
    AND AVG(U.Reputation) > 100  -- Only include posts by users with reputation over 100.
    AND RPh.Level = 1  -- Only include direct close actions.
