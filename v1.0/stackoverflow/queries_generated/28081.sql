WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Selecting only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last 1 year
),

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Posts p
    INNER JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        ts.TagName
    FROM 
        RankedPosts rp
    JOIN 
        TagStats ts ON rp.Title ILIKE '%' || ts.TagName || '%'
    WHERE 
        rp.RankByViews <= 5 -- Top 5 most viewed questions per user
)

SELECT 
    tp.PostId,
    tp.Title AS QuestionTitle,
    tp.ViewCount AS QuestionViewCount,
    ts.TagName AS RelatedTag,
    ts.PostCount AS TagUsageCount,
    ts.AvgViewCount AS AvgViewCountForTag,
    ts.TopUsers AS TopContributors
FROM 
    TopPosts tp
JOIN 
    TagStats ts ON tp.TagName = ts.TagName
ORDER BY 
    tp.ViewCount DESC, ts.PostCount DESC;
