WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with a positive score
),
PopularTags AS (
    SELECT 
        Tags,
        COUNT(*) AS TotalQuestions,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        Tags
    HAVING 
        COUNT(*) > 5 -- At least 6 questions to be considered popular
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    pt.Tags AS PopularTags
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags = pt.Tags
WHERE 
    rp.TagRank <= 5 -- Top 5 ranked posts per tag
ORDER BY 
    pt.TotalViews DESC, rp.ViewCount DESC;
