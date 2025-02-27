WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.Reputation
),
RecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Reputation,
        PostRank,
        CommentCount
    FROM RankedPosts
    WHERE CreationDate >= NOW() - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        UNNEST(string_to_array(Tags, ','))
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Reputation,
    rp.CommentCount,
    tt.TagName
FROM 
    RecentPosts rp
    LEFT JOIN TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    rp.Score > (SELECT AVG(Score) FROM RecentPosts) 
    AND rp.CommentCount > 5 
    OR (tt.TagName IS NOT NULL AND tt.TagCount > 2)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
