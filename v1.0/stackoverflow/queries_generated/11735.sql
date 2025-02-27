-- Performance Benchmarking Query
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerName,
    P.AnswerCount,
    P.CommentCount,
    P.ViewCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id) AS EditHistoryCount
FROM 
    Posts P
INNER JOIN 
    Users U ON P.OwnerUserId = U.Id 
WHERE 
    P.PostTypeId = 1 -- Filtering for Questions
ORDER BY 
    P.CreationDate DESC
LIMIT 100; -- Limiting to the most recent 100 questions
