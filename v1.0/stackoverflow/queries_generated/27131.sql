WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Question type
        AND p.CreationDate > NOW() - interval '30 days' -- Filter for the last 30 days
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
    GROUP BY 
        t.TagName
),

CombinedStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        TagStatistics ts ON ts.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
)

SELECT 
    cs.PostId,
    cs.Title,
    cs.Body,
    cs.Tags,
    cs.CreationDate,
    cs.ViewCount,
    cs.Score,
    cs.OwnerDisplayName,
    cs.TagName,
    cs.PostCount,
    cs.QuestionCount,
    cs.AnswerCount
FROM 
    CombinedStatistics cs
WHERE 
    cs.RankByViews <= 3 -- Top 3 posts by views in their locations
    OR cs.RankByScore <= 3 -- Top 3 posts by score per tag
ORDER BY 
    cs.TagName, cs.ViewCount DESC, cs.Score DESC;
