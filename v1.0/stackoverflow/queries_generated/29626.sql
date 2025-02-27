WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(Tags FROM 1 FOR POSITION('>' IN Tags)-1) ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Posts created in the last year
        AND p.Score > 0  -- Only questions with a positive score
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTag <= 5  -- Top 5 questions by score per tag
),
TagsWithPosts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT tq.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        TopQuestions tq ON tq.Tags LIKE '%<%#' || t.TagName || '%>%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
),
TagMetrics AS (
    SELECT 
        TagName,
        PostCount,
        CASE 
            WHEN PostCount > 10 THEN 'High'
            WHEN PostCount BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low' 
        END AS TagLevel
    FROM 
        TagsWithPosts
)
SELECT 
    t.TagName,
    t.PostCount,
    tm.TagLevel,
    CASE 
        WHEN tm.TagLevel = 'High' THEN 'Trending Topic'
        WHEN tm.TagLevel = 'Medium' THEN 'Moderate Interest'
        ELSE 'Low Community Engagement'
    END AS EngagementLevel
FROM 
    TagMetrics tm
JOIN 
    Tags t ON t.TagName = tm.TagName
WHERE 
    tm.PostCount > 0  -- Filter only tags with associated posts
ORDER BY 
    t.PostCount DESC;
