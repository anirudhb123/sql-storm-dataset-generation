WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY ARRAY(SELECT unnest(string_to_array(p.Tags, '><'))) ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 10 -- Top 10 posts for each tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    CONCAT('https://stackoverflow.com/questions/', fp.PostId) AS PostLink,
    COALESCE((SELECT STRING_AGG(DISTINCT bt.Name, ', ') 
              FROM Badges b
              JOIN Users u ON b.UserId = u.Id
              JOIN BadgesTypes bt ON b.Id = bt.Id
              WHERE u.Id = fp.OwnerDisplayName), 'No badges') AS OwnerBadges
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 50;

This SQL query benchmarks string processing by computing the top questions in the Stack Overflow context, grouped by tags. It ranks the posts based on their score within their respective tags, filtering to the top 10, and aggregates user badge information, thus showcasing complex string manipulations with `string_to_array`, `STRING_AGG`, and various conditional aggregations.
