-- Performance benchmarking query

-- This query fetches details of posts along with the number of comments and votes for each post
-- It joins several tables to gather comprehensive data about each post, its author, and its interaction metrics

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS AuthorName,
    COUNT(C.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    P.Score,
    P.ViewCount,
    P.Tags
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 1000; -- Limiting to the latest 1000 posts for performance evaluation
