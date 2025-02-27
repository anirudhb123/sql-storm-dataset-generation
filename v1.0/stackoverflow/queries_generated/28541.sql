WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(TRIM(BOTH '<>' FROM unnest(string_to_array(p.Tags, '>'))) ORDER BY p.ViewCount DESC) ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year.
),

TopTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM unnest(string_to_array(Tags, '>'))) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5  -- Tags used in more than 5 posts
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        ARRAY_AGG(tt.Tag) AS RelatedTags
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON tt.Tag = ANY(string_to_array(rp.Tags, '>'))
    WHERE 
        rp.TagRank <= 10  -- Only top 10 ranked posts per tag
    GROUP BY 
        rp.PostId, 
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.RelatedTags,
    COALESCE(CAST(ROUND(AVG(v.BountyAmount), 2) AS VARCHAR), 'No Bounties') AS AverageBounty
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 8 -- Only bounties
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
LIMIT 50;  -- Limit to 50 results for performance
