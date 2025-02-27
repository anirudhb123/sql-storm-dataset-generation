WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        unnest(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM
        TaggedPosts
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 -- Only tags used more than 5 times
),
TopPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        pt.Tag AS PopularTag
    FROM 
        TaggedPosts tp
    JOIN 
        PopularTags pt ON tp.Tag = pt.Tag
    WHERE 
        tp.Score > 10 -- Selecting only posts with a score greater than 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    pt.PopularTag
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10; -- Getting the top 10 posts with the most score and views
