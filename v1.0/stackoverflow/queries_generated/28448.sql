WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_names
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS RankScore
    FROM 
        RankedPosts rp
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.AnswerCount,
    fp.Tags,
    fp.RankScore
FROM 
    FilteredPosts fp
WHERE 
    fp.RankScore <= 10 -- Top 10 questions based on score and view count
ORDER BY 
    fp.RankScore;

This SQL query benchmarks string processing through the aggregation of post-related data, including tags, comments, and answers, focused specifically on questions from the posts table. It ranks posts based on their scores and view counts, which can be useful for understanding the impact of string manipulation on performance.
