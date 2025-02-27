
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE) 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
),
TagsExploded AS (
    SELECT 
        tp.PostId,
        value AS Tag
    FROM 
        TopPosts tp
        CROSS APPLY STRING_SPLIT(tp.Tags, '><') AS TagValues(value)
),
TagCount AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount
    FROM 
        TagsExploded
    GROUP BY 
        Tag
)
SELECT 
    t.Tag,
    t.PostCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId IN (SELECT PostId FROM TopPosts)) AS TotalComments
FROM 
    TagCount t
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' + t.Tag + '%'
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
GROUP BY 
    t.Tag, t.PostCount
ORDER BY 
    t.PostCount DESC;
