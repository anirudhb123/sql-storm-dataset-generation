WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),

PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '<>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount,
        pt.Name AS PostType,
        rt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        PopularTags rt ON rt.TagName = ANY(string_to_array(p.Tags, '<>'))
    WHERE 
        rp.Rank <= 5
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.LastActivityDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount,
    pm.PostType,
    STRING_AGG(pm.TagName, ', ') AS RelatedTags
FROM 
    PostMetrics pm
GROUP BY 
    pm.PostId, pm.Title, pm.CreationDate, pm.LastActivityDate, pm.Score, pm.ViewCount, pm.AnswerCount, pm.CommentCount, pm.FavoriteCount, pm.PostType
ORDER BY 
    pm.Score DESC;
