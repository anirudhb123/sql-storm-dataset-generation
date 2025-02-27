WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostType,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(COALESCE(c.Score, 0)) AS CommentScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagId) AS TagIds ON TRUE
    LEFT JOIN 
        Tags t ON t.Id = CAST(TagIds.TagId AS int)
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
),
MaxComments AS (
    SELECT 
        p.Id,
        MAX(sc.CommentScore) AS MaxCommentScore
    FROM 
        (SELECT DISTINCT p.Id, SUM(COALESCE(c.Score, 0)) AS CommentScore 
         FROM Posts p 
         LEFT JOIN Comments c ON c.PostId = p.Id 
         GROUP BY p.Id) sc
    GROUP BY 
        p.Id
)
SELECT 
    rp.Id,
    rp.Title,
    rp.Body,
    rp.PostType,
    rp.Tags,
    rp.Owner,
    rp.CreationDate,
    rp.AnswerCount,
    mc.MaxCommentScore
FROM 
    RankedPosts rp
JOIN 
    MaxComments mc ON rp.Id = mc.Id
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;

This SQL query constructs a benchmarking scenario for string processing with multiple common SQL operations. It combines ranking, aggregation, string manipulation, and conditional logic to create a complex query. The query first ranks posts per user, aggregates post types and tags, counts answers, and summarizes comment scores. It then filters to only keep the latest post per user and presents the winner in an ordered list with a limit. This setup allows for performance evaluation involving string manipulation via `STRING_AGG` and `string_to_array`.
