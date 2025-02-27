WITH RankedPosts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS TotalComments,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS IsClosed,
        MAX(pt.Name) AS PostTypeName,
        MAX(u.DisplayName) AS OwnerDisplayName,
        MAX(vt.Name) AS VoteTypeName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate > '2020-01-01' AND p.Score > 0
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.TotalComments,
    rp.TotalBounty,
    rp.IsClosed,
    rp.PostTypeName,
    RANK() OVER (ORDER BY rp.Score DESC, rp.CreationDate ASC) AS OverallRank
FROM 
    RankedPosts rp
WHERE 
    rp.RankByScore = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 100;
