WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS ProcessedTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '> <'))::varchar[]) AS TagName
         FROM 
            Posts) t ON p.Id = t.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),
PostActivity AS (
    SELECT 
        pp.PostId,
        pp.OwnerDisplayName,
        pp.Title,
        pp.ViewCount,
        pp.Score,
        pp.CommentCount,
        CASE 
            WHEN pp.Score > 100 THEN 'Hot'
            WHEN pp.ViewCount > 1000 THEN 'Popular'
            ELSE 'Standard'
        END AS PostClass,
        ph.CreationDate AS LastEditDate
    FROM 
        ProcessedPosts pp
    LEFT JOIN 
        PostHistory ph ON pp.PostId = ph.PostId
    WHERE 
        ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = pp.PostId)
)
SELECT 
    pa.PostId,
    pa.OwnerDisplayName,
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.PostClass,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM 
    PostActivity pa
LEFT JOIN 
    PostLinks pl ON pa.PostId = pl.PostId
GROUP BY 
    pa.PostId, pa.OwnerDisplayName, pa.Title, pa.ViewCount, pa.Score, pa.CommentCount, pa.PostClass
ORDER BY 
    pa.PostClass DESC, pa.Score DESC
LIMIT 50;
