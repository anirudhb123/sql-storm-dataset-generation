
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
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),

TagArray AS (
    SELECT 
        PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        FilteredPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
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
    GROUP_CONCAT(fp.Title SEPARATOR '; ') AS QuestionTitles  
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
