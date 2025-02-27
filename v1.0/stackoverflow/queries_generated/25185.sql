WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY(
            SELECT TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
            ) AS TagName
        ) AS TagsArray,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostScores AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetScore
    FROM 
        Votes v
    GROUP BY 
        PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(ARRAY(SELECT TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))::int)))
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ps.NetScore,
    rp.TagsArray,
    rp.OwnerDisplayName,
    tt.TagName AS PopularTag
FROM 
    RecentPosts rp
LEFT JOIN 
    PostScores ps ON rp.PostId = ps.PostId
LEFT JOIN 
    TopTags tt ON tt.TagName = ANY(rp.TagsArray)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 20;
