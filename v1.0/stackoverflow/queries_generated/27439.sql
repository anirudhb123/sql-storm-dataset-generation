WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for the last year
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Author
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Top 5 questions per tag
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        COUNT(*) DESC
    LIMIT 10 -- Top 10 popular tags
)
SELECT 
    t.TagName,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Author
FROM 
    TopPosts tp
JOIN 
    PopularTags t ON tp.Title ILIKE '%' || t.TagName || '%' -- Match titles to tags
ORDER BY 
    t.TagName, tp.Score DESC;
