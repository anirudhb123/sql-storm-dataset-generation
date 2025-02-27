WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  -- Questions and Answers only
),
TagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t 
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Id IN (1, 2)  -- Questions and Answers only
    GROUP BY 
        t.Id, t.TagName
),
PopularTags AS (
    SELECT 
        tc.TagId,
        tc.TagName,
        tc.PostCount,
        ROW_NUMBER() OVER (ORDER BY tc.PostCount DESC) AS TagRank
    FROM 
        TagCounts tc
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.ViewCount,
    rp.Score,
    pt.TagName,
    pt.PostCount AS RelatedTagPostCount,
    pt.TagRank
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    Tags tg ON p.Tags LIKE '%' || tg.TagName || '%'
JOIN 
    PopularTags pt ON tg.Id = pt.TagId
WHERE 
    rp.Rank <= 5  -- Top 5 Posts per PostType
    AND pt.TagRank <= 10  -- Top 10 Tags by Post Count
ORDER BY 
    rp.PostId, pt.TagRank;
