WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0
),
TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))) ) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')))
),
PopularTags AS (
    SELECT 
        TagName,
        TagCount
    FROM 
        TagCounts
    WHERE 
        TagCount > 50 -- Only retain popular tags
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostRank = 1
    WHERE 
        EXISTS (
            SELECT 1 
            FROM Posts p 
            WHERE p.Id = rp.PostId 
            AND EXISTS (
                SELECT 1 
                FROM PopularTags
                WHERE position(PopularTags.TagName in rp.Tags) > 0
            )
        )
)
SELECT 
    pd.OwnerDisplayName,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    COUNT(c.Id) AS CommentCount,
    ARRAY_AGG(DISTINCT tag.TagName) AS PopularTags
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
LEFT JOIN 
    PopularTags tag ON position(tag.TagName in pd.Tags) > 0
GROUP BY 
    pd.OwnerDisplayName, pd.Title, pd.CreationDate, pd.Score, pd.ViewCount
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 10;
