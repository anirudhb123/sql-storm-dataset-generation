
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
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS TagPostCount,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
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
        MostDiscussed mp ON mp.Tags LIKE CONCAT('%', t.TagName, '%') 
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
