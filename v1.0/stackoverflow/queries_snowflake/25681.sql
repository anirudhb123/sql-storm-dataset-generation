
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
        AND p.Body IS NOT NULL 
),

MostDiscussed AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),

TagStats AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagPostCount,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts,
        LATERAL SPLIT_TO_TABLE(Tags, '>') AS tag
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(value)
),

AggregatedTags AS (
    SELECT 
        t.TagName,
        ts.TagPostCount,
        ts.AcceptedAnswers,
        COALESCE(SUM(mp.Score), 0) AS TotalScore,
        COALESCE(SUM(mp.ViewCount), 0) AS TotalViews
    FROM 
        TagStats ts
    JOIN 
        Tags t ON t.TagName = ts.TagName
    LEFT JOIN 
        MostDiscussed mp ON mp.Tags LIKE '%' || t.TagName || '%' 
    GROUP BY 
        t.TagName, ts.TagPostCount, ts.AcceptedAnswers
)

SELECT 
    at.TagName,
    at.TagPostCount,
    at.AcceptedAnswers,
    at.TotalScore,
    at.TotalViews,
    (CAST(at.TotalScore AS DECIMAL) / NULLIF(at.TagPostCount, 0)) AS AvgScorePerPost,
    (CAST(at.TotalViews AS DECIMAL) / NULLIF(at.TagPostCount, 0)) AS AvgViewsPerPost
FROM 
    AggregatedTags at
ORDER BY 
    AvgScorePerPost DESC
LIMIT 10;
