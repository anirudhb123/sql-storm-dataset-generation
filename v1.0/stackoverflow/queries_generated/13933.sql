-- Performance benchmarking query for the StackOverflow schema
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId -- Count answers
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
)
SELECT 
    *,
    (UpVotes - DownVotes) AS NetVotes
FROM 
    PostStatistics
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100; -- Limit to top 100 posts by score and views for benchmarking
