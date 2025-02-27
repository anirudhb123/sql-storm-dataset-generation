WITH RecursivePosts AS (
    -- Recursive Common Table Expression to traverse posts and their accepted answers
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AcceptedAnswerId,
        0 AS Depth
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Starting with questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.AcceptedAnswerId,
        RP.Depth + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePosts RP ON RP.AcceptedAnswerId = P2.Id
)

-- Main Query to benchmark performance with various SQL constructs
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS QuestionCount,
    COUNT(DISTINCT C.Id) AS CommentCount,
    AVG(V.BountyAmount) AS AverageBounty,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    MAX(P.CreationDate) AS LastQuestionDate,
    COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS ClosureChanges,
    COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (1, 4, 6)) AS TitleTagEdits
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- Bounty votes
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%' -- Tag association
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    U.Reputation > 1000 -- Filtering users with reputation greater than 1000
GROUP BY 
    U.Id
HAVING 
    COUNT(DISTINCT P.Id) > 5 -- Users should have more than 5 questions
ORDER BY 
    TotalViews DESC
LIMIT 10;

-- Final output includes Users with their performance metrics along with tags, closure changes, and edits.
