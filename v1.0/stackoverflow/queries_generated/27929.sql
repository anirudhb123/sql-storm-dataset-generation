WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
        AND p.Score > 0 -- Only posts with a score greater than 0
),
TopPostTags AS (
    SELECT 
        Tags,
        STRING_AGG(DISTINCT Title, ', ') AS TopPosts,
        COUNT(PostId) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 posts per tag
    GROUP BY 
        Tags
)
SELECT 
    t.Tags,
    t.TopPosts,
    t.PostCount,
    COUNT(b.Id) AS BadgeCount
FROM 
    TopPostTags t
LEFT JOIN 
    Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags = t.Tags)
GROUP BY 
    t.Tags, t.TopPosts, t.PostCount
ORDER BY 
    PostCount DESC;

