
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        TotalComments,
        TotalVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats, (SELECT @rank := 0) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    TotalComments,
    TotalVotes
FROM 
    TopPosts
WHERE 
    Rank <= 10;
