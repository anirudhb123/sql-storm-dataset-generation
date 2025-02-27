WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
FilteredTags AS (
    SELECT 
        UNNEST(string_to_array(Trim(both '<>' from Tags), '><')) AS Tag
    FROM 
        RankedPosts
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10 -- Only tags with more than 10 questions
),
TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    JOIN 
        FilteredTags ft ON rp.Tags LIKE '%' || ft.Tag || '%'
    WHERE 
        rp.TagRank <= 5 -- Top 5 ranked posts per tag
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC
LIMIT 50; -- Fetching the top 50 posts based on view count and creation date
