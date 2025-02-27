WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on recently created posts
        AND p.PostTypeId = 1  -- Only questions
), TagInfo AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')  -- Finding posts containing the tag
    LEFT JOIN 
        PostLinks pl ON pl.RelatedPostId = p.Id
    WHERE 
        pl.LinkTypeId = 1  -- Only linked posts
    GROUP BY 
        t.Id, t.TagName
), MostPopularTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagInfo
    WHERE 
        PostCount > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    mt.TagName AS MostPopularTag,
    rp.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    MostPopularTags mt ON mt.TagRank = 1  -- Join to get the most popular tag
WHERE 
    rp.Rank <= 10  -- Limit results to the top 10 questions by score
ORDER BY 
    rp.Score DESC;
