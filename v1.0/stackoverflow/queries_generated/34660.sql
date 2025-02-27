WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),

QuestionStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN COALESCE(a.AnswerCount, 0) > 0 THEN ROUND((COALESCE(c.CommentCount, 0) * 1.0) / COALESCE(a.AnswerCount, 1), 2)
            ELSE 0
        END AS CommentsPerAnswer
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- Answers only
        GROUP BY 
            ParentId
    ) a ON rp.PostId = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON rp.PostId = c.PostId
)

SELECT 
    qs.PostId,
    qs.Title,
    qs.Author,
    qs.CreationDate,
    qs.Score,
    qs.ViewCount,
    qs.CommentCount,
    qs.AnswerCount,
    qs.CommentsPerAnswer,
    -- Get most recent edit history for the post
    (SELECT 
        ph.CreationDate 
     FROM 
        PostHistory ph
     WHERE 
        ph.PostId = qs.PostId
     ORDER BY 
        ph.CreationDate DESC 
     LIMIT 1) AS LastEditDate
FROM 
    QuestionStatistics qs
WHERE 
    qs.Rank = 1 -- only top-ranked questions per user
ORDER BY 
    qs.Score DESC, 
    qs.ViewCount DESC
LIMIT 100; -- Limit the number of results to the top 100
