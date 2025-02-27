WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
TagUsage AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName
    FROM 
        TagUsage
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.NetVotes,
    rp.CommentCount,
    (SELECT STRING_AGG(tu.TagName, ', ') 
     FROM TopTags tu 
     WHERE rp.Tags ILIKE '%' || tu.TagName || '%') AS PopularTags
FROM 
    RankedPosts rp
WHERE 
    rp.RankPerUser <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
