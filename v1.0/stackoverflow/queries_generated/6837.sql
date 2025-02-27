WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY (string_to_array(p.Tags, ',')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 10
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        pt.UsageCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PopularTags pt ON pt.UsageCount > 0
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    OwnerDisplayName,
    UsageCount,
    PostCategory
FROM 
    PostMetrics
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;
