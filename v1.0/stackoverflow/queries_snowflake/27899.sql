
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS Author,
        u.Reputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1   
        AND p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'   
),

TagArray AS (
    SELECT 
        PostId,
        TRIM(value) AS Tag
    FROM 
        FilteredPosts,
        TABLE(FLATTEN(input => SPLIT(TRIM(BOTH '{}' FROM Tags), '><'))) AS f
),

TagStats AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount, 
        AVG(ViewCount) AS AvgViewCount, 
        AVG(Score) AS AvgScore
    FROM 
        TagArray ta
    JOIN 
        FilteredPosts fp ON ta.PostId = fp.PostId
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10   
)

SELECT 
    ts.Tag,
    ts.TagCount,
    ts.AvgViewCount,
    ts.AvgScore,
    LISTAGG(fp.Title, '; ') AS QuestionTitles  
FROM 
    TagStats ts
JOIN 
    TagArray ta ON ts.Tag = ta.Tag
JOIN 
    FilteredPosts fp ON ta.PostId = fp.PostId
GROUP BY 
    ts.Tag, ts.TagCount, ts.AvgViewCount, ts.AvgScore
ORDER BY 
    ts.TagCount DESC;
