WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(Tags, '<>'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts from the last year
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  -- Top 10 questions by score
),

TagSummary AS (
    SELECT
        TRIM(tag) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS tag
    GROUP BY 
        TRIM(tag)
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tq.OwnerDisplayName,
    tq.TagCount,
    ts.TagName,
    ts.PostCount
FROM 
    TopQuestions tq
LEFT JOIN 
    TagSummary ts ON ts.PostCount > 5  -- Only include tags with more than 5 posts
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
