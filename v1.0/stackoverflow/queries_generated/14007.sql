-- Performance benchmarking query to analyze Posts, Votes, and Users
WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' -- Consider posts created in 2023 for analysis
    GROUP BY 
        P.Id, U.Reputation, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, AnswerCount, CommentCount, VoteCount, OwnerReputation, OwnerDisplayName
    FROM 
        PostSummary
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10 -- Get top 10 posts by score and views
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.VoteCount,
    TP.OwnerReputation,
    TP.OwnerDisplayName
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC;
