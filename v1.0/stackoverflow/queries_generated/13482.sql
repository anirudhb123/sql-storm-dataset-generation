-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(V.Id) AS VoteCount,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1  -- Filtering for questions only
    GROUP BY 
        P.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        OwnerDisplayName,
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    OwnerDisplayName,
    VoteCount
FROM 
    TopPosts
WHERE 
    Rank <= 10; -- Fetching top 10 questions based on score
