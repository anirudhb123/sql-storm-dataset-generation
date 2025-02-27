
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(co.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerRank <= 5 
),
PostAggregates AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AverageScore,
        SUM(CommentCount) AS TotalComments
    FROM 
        TopPosts
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    pa.TotalPosts,
    pa.AverageScore,
    pa.TotalComments
FROM 
    TopPosts tp
CROSS JOIN 
    PostAggregates pa
ORDER BY 
    tp.Score DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
