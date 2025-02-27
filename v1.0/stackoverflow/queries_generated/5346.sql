WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, ',')) AS tag ON true
    LEFT JOIN 
        Tags t ON tag::varchar = t.TagName
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 5  -- Top 5 posts per user
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(tp.PostId) AS TotalPosts,
    AVG(tp.Score) AS AvgScore,
    SUM(tp.ViewCount) AS TotalViews,
    STRING_AGG(DISTINCT tp.Tags, ', ') AS AllTags
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 10; -- Top 10 users with the most top posts
