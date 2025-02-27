WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 AND 
        Score > 10 -- Only well-scored questions
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName
    FROM 
        FilteredPosts
),
TagCount AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        TopTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  -- Only consider tags with more than 5 posts
),
PopularQuestions AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.OwnerDisplayName,
        tc.TagName
    FROM 
        FilteredPosts fp
    JOIN 
        TagCount tc ON tc.PostCount > 5
    ORDER BY 
        fp.Score DESC, fp.CreationDate DESC
)
SELECT 
    pq.PostId,
    pq.Title,
    pq.CreationDate,
    pq.Score,
    pq.OwnerDisplayName,
    STRING_AGG(DISTINCT tc.TagName, ', ') AS RelatedTags
FROM 
    PopularQuestions pq
JOIN 
    TopTags tt ON pq.PostId IN (SELECT DISTINCT PostId FROM FilteredPosts)
LEFT JOIN 
    TagCount tc ON tc.TagName IN (SELECT unnest(string_to_array(pq.Tags, ',')))
GROUP BY 
    pq.PostId, pq.Title, pq.CreationDate, pq.Score, pq.OwnerDisplayName
ORDER BY 
    pq.Score DESC, pq.CreationDate DESC
LIMIT 10; -- Limit to top 10 results
