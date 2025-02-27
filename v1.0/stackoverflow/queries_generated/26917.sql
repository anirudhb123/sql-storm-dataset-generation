WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        t.TagName,
        u.DisplayName AS AuthorName,
        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY p.ViewCount DESC) AS RankInTag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.TagName,
        rp.AuthorName
    FROM 
        RankedPosts rp
    WHERE 
        RankInTag <= 5
),
PostStats AS (
    SELECT 
        tp.TagName,
        COUNT(tp.PostId) AS NumberOfTopQuestions,
        AVG(tp.ViewCount) AS AverageViewCount,
        AVG(tp.Score) AS AverageScore,
        AVG(tp.AnswerCount) AS AverageAnswerCount,
        AVG(tp.CommentCount) AS AverageCommentCount
    FROM 
        TopPosts tp
    GROUP BY 
        tp.TagName
)
SELECT 
    ps.TagName,
    ps.NumberOfTopQuestions,
    ps.AverageViewCount,
    ps.AverageScore,
    ps.AverageAnswerCount,
    ps.AverageCommentCount
FROM 
    PostStats ps
ORDER BY 
    ps.NumberOfTopQuestions DESC,
    ps.AverageViewCount DESC;
