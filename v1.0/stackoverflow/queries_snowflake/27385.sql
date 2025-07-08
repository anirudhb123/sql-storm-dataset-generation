
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
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON tag_name.VALUE = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
TopViewedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.TagsArray
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewRank <= 10 
),
Analytics AS (
    SELECT 
        tp.OwnerDisplayName,
        COUNT(tp.PostId) AS TotalPosts,
        SUM(tp.CommentCount) AS TotalComments,
        AVG(tp.ViewCount) AS AvgViewCount
    FROM 
        TopViewedPosts tp
    GROUP BY 
        tp.OwnerDisplayName
)
SELECT 
    a.OwnerDisplayName,
    a.TotalPosts,
    a.TotalComments,
    a.AvgViewCount,
    LISTAGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Analytics a
LEFT JOIN 
    TopViewedPosts tp ON tp.OwnerDisplayName = a.OwnerDisplayName
LEFT JOIN 
    LATERAL FLATTEN(INPUT => tp.TagsArray) AS t ON TRUE
GROUP BY 
    a.OwnerDisplayName, a.TotalPosts, a.TotalComments, a.AvgViewCount
ORDER BY 
    a.TotalPosts DESC, a.TotalComments DESC;
