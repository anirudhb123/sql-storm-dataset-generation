
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        LEN(REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', ','), '<', '')) - LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', '')) + 1 AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagDetails AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(pm.ViewCount) AS TotalViews,
        AVG(pm.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    LEFT JOIN 
        PostMetrics pm ON pm.PostId = p.Id
    GROUP BY 
        t.TagName
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.OwnerDisplayName,
        pm.OwnerReputation,
        pm.ViewCount,
        pm.AnswerCount,
        pm.CommentCount,
        pm.FavoriteCount,
        pm.TagCount,
        pm.CreationDate
    FROM 
        PostMetrics pm
    ORDER BY 
        pm.Score DESC, pm.ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    td.TagName,
    td.PostCount,
    td.TotalViews,
    td.AverageScore,
    tp.Title AS TopPostTitle,
    tp.OwnerDisplayName AS TopPostOwner,
    tp.ViewCount AS TopPostViewCount,
    tp.CreationDate AS TopPostCreationDate
FROM 
    TagDetails td
LEFT JOIN 
    TopPosts tp ON tp.TagCount > 0
ORDER BY 
    td.PostCount DESC, td.TotalViews DESC;
