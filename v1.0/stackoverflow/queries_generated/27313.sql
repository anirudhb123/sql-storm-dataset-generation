WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
),
TagMetrics AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        COUNT(DISTINCT pt.PostId) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag, 
        TagCount, 
        PostCount, 
        AvgUserReputation
    FROM 
        TagMetrics
    WHERE 
        TagCount > (SELECT AVG(TagCount) FROM TagMetrics)
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ARRAY_AGG(DISTINCT pt.Tag) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTags pt ON p.Id = pt.PostId
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        p.Id
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.Score,
    tq.ViewCount,
    tq.AnswerCount,
    tq.CommentCount,
    tq.CreationDate,
    pt.Tag AS PopularTag,
    pm.TagCount,
    pm.PostCount,
    pm.AvgUserReputation
FROM 
    TopQuestions tq
JOIN 
    PopularTags pm ON pm.Tag = ANY(tq.Tags)
ORDER BY 
    tq.Score DESC, 
    pm.TagCount DESC;

This query benchmarks string processing by extracting tags from questions, computing metrics on those tags, and joining relevant question statistics. It identifies popular tags based on thresholds and matches them with top questions to display comprehensive information.
