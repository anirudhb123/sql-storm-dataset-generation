WITH RecursivePostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.OwnerUserId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only include Questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Score,
        P2.OwnerUserId,
        Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        Posts P ON P2.ParentId = P.Id
    WHERE 
        P.PostTypeId = 1 AND P2.PostTypeId = 2  -- Join Answers to Questions
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT PS.PostId) AS TotalPosts,
    SUM(CASE WHEN PS.Score IS NOT NULL THEN PS.Score ELSE 0 END) AS TotalScore,
    COUNT(DISTINCT H.PostId) AS EditCount,
    COUNT(DISTINCT V.Id) AS VoteCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    RecursivePostScores PS ON P.Id = PS.PostId
LEFT JOIN 
    PostHistory H ON P.Id = H.PostId AND H.PostHistoryTypeId IN (4, 5, 6)  -- Edits: Title, Body, Tags
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    STRING_TO_ARRAY(P.Tags, ',') AS T ON TRUE  -- Extract Tags directly from Post
WHERE 
    U.Reputation > 1000  -- Only high-reputation users
GROUP BY 
    U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT P.Id) > 5  -- Users should have posted more than 5 times
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
