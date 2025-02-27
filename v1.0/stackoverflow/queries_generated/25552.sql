WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ARRAY(SELECT DISTINCT TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) 
               ) ORDER BY TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))  ) AS PostTags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        rp.PostTags,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND  -- More than 5 comments
        rp.AnswerCount > 2       -- More than 2 answers
),
PostTypesCount AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS Count 
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.PostTypeId
)
SELECT 
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.AnswerCount,
    pt.Count AS RecentPostTypesCount,
    STRING_AGG(DISTINCT tag, ', ') AS UniqueTags
FROM 
    FilteredPosts fp
JOIN 
    PostTypesCount pt ON 1=1 -- Joining for a total of all post types
LEFT JOIN 
    UNNEST(fp.PostTags) AS tag ON true
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerName, fp.CreationDate, fp.Score, fp.ViewCount, fp.CommentCount, fp.AnswerCount, pt.Count
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
