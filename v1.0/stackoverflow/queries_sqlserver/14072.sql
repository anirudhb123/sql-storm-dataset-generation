
WITH BenchmarkData AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        P.Body
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.LastActivityDate, P.Score, P.ViewCount, P.Body
)

SELECT 
    PostId,
    Title,
    Author,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    CreationDate,
    LastActivityDate,
    Score,
    ViewCount,
    Body,
    DATEDIFF(MINUTE, CreationDate, LastActivityDate) AS TimeToActivityMinutes,
    (CAST(ViewCount AS FLOAT) / NULLIF(CommentCount, 0)) AS ViewPerComment,
    (CAST(Score AS FLOAT) / NULLIF(ViewCount, 0)) AS ScorePerView
FROM 
    BenchmarkData
ORDER BY 
    Score DESC, ViewCount DESC;
