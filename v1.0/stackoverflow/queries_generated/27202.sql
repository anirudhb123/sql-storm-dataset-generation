WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.Tags, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        rp.CommentCount > 5 AND rp.Score > 10
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.CreationDate, rp.Tags, rp.OwnerName, rp.Rank
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerName,
    p.ViewCount,
    p.Score,
    p.AllTags,
    p.Rank
FROM 
    PopularPosts p
WHERE 
    p.Rank <= 3
ORDER BY 
    p.Score DESC;

This SQL query benchmarks string processing and retrieves the top questions from the `Posts` table that have a significant number of comments and a score above a certain threshold. It incorporates string manipulation by parsing the tags associated with each post, aggregating them into a single string for each post. The query ranks posts per user, filtering out the top three posts based on score, to provide a summary of high-engagement content.
