WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(ph.CreationDate) AS AvgEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.OwnerUserId, p.Score
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.Rank,
    rp.VoteCount,
    rp.CommentCount,
    rp.AvgEditDate
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.OwnerUserId, rp.Score DESC;
