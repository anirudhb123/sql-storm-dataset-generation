WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Considering Questions and Answers
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank = 1  -- Select the highest scored post per user
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostScores AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.AnswerCount,
        tp.CommentCount,
        pco.TotalComments
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pco ON tp.PostId = pco.PostId
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    COALESCE(ps.TotalComments, 0) AS TotalComments
FROM 
    PostScores ps
ORDER BY 
    ps.Score DESC, 
    ps.CreationDate ASC
LIMIT 10;
