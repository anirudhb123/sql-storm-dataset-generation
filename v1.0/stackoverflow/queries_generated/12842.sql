-- Performance Benchmarking Query for Stack Overflow schema
-- This query retrieves a summary of posts alongside related user information, tags, and vote counts.

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    T.TagName,
    V.UpVoteCount,
    V.DownVoteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
     FROM Votes
     GROUP BY PostId) V ON P.Id = V.PostId
LEFT JOIN 
    (SELECT PostId, STRING_AGG(TagName, ', ') AS TagName
     FROM PostTags
     JOIN Tags T ON PostTags.TagId = T.Id
     GROUP BY PostId) T ON P.Id = T.PostId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    P.Score DESC, P.CreationDate DESC
LIMIT 100;
