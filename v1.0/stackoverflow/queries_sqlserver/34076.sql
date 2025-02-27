
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE)
),
TagOverview AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalScore
    FROM 
        TagOverview
    WHERE 
        PostCount > 0
    ORDER BY 
        TotalScore DESC
    OFFSET 0 ROWS
    FETCH NEXT 5 ROWS ONLY
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerReputation,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    tt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentCounts cc ON rp.PostId = cc.PostId
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    TopTags tt ON p.Tags LIKE '%' + tt.TagName + '%'
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
