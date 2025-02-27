
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS date)
        AND p.Body IS NOT NULL
),

TagDetails AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') AS value
    WHERE 
        p.Tags IS NOT NULL
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COUNT(DISTINCT cd.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS EditCount,
        AVG(b.Rank) AS AverageScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments cd ON rp.PostId = cd.PostId
    LEFT JOIN 
        PostHistory bh ON rp.PostId = bh.PostId AND bh.PostHistoryTypeId IN (4, 5, 6)  
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Rank
        FROM 
            Votes
        GROUP BY 
            PostId
    ) b ON rp.PostId = b.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.EditCount,
    ps.AverageScore,
    td.Tag
FROM 
    PostStatistics ps
JOIN 
    TagDetails td ON ps.PostId = td.PostId
WHERE 
    ps.AverageScore IS NOT NULL
ORDER BY 
    ps.AverageScore DESC, 
    ps.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
