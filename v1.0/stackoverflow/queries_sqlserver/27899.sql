
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
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)   
),

TagArray AS (
    SELECT 
        PostId,
        value AS Tag
    FROM 
        FilteredPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)

SELECT 
    ts.Tag,
    ts.TagCount,
    ts.AvgViewCount,
    ts.AvgScore,
    STRING_AGG(fp.Title, '; ') AS QuestionTitles  
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
