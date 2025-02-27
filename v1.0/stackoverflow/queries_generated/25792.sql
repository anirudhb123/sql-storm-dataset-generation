WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.AnswerCount > 0 
        AND rp.CreationDate >= NOW() - INTERVAL '30 days' 
        AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) > 5 -- At least 5 comments
), TagStats AS (
    SELECT 
        tag.TagName,
        COUNT(fp.PostId) AS PostCount,
        AVG(fp.AnswerCount) AS AvgAnswers
    FROM 
        FilteredPosts fp
    CROSS JOIN 
        LATERAL STRING_TO_ARRAY(fp.Tags, ',') AS tag -- Assuming Tags are comma-separated
    GROUP BY 
        tag.TagName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AvgAnswers,
    CASE 
        WHEN ts.PostCount > 10 THEN 'Popular'
        WHEN ts.PostCount BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular' 
    END AS Popularity
FROM 
    TagStats ts
ORDER BY 
    ts.AvgAnswers DESC, 
    ts.PostCount DESC
LIMIT 10;
