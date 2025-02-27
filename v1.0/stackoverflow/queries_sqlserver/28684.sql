
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.AnswerCount DESC) AS AnswerRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate BETWEEN '2022-01-01' AND '2023-10-31'  
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        CASE 
            WHEN rp.ViewRank = 1 THEN 'Most Viewed'
            WHEN rp.AnswerRank = 1 THEN 'Most Answered'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
),
TopTags AS (
    SELECT 
        LTRIM(RTRIM(value)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        LTRIM(RTRIM(value))
    ORDER BY 
        TagCount DESC
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.PostCategory,
    tt.Tag AS TopTag
FROM 
    PostStats ps
JOIN 
    TopTags tt ON ps.Body LIKE '%' + tt.Tag + '%'
ORDER BY 
    ps.ViewCount DESC,
    ps.AnswerCount DESC;
