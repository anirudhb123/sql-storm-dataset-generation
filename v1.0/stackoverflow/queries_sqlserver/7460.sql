
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        tp.OwnerDisplayName,
        c.Text AS CommentText,
        c.CreationDate AS CommentDate,
        ph.Comment AS PostHistoryComment,
        ph.CreationDate AS PostHistoryDate
    FROM 
        TopPosts tp
        LEFT JOIN Comments c ON tp.PostId = c.PostId
        LEFT JOIN PostHistory ph ON tp.PostId = ph.PostId
    ORDER BY 
        tp.Score DESC, 
        tp.ViewCount DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    STRING_AGG(DISTINCT CommentText, ',') AS Comments,
    STRING_AGG(DISTINCT PostHistoryComment, ',') AS PostHistoryComments
FROM 
    PostDetails
GROUP BY 
    PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, OwnerDisplayName
ORDER BY 
    Score DESC, ViewCount DESC;
