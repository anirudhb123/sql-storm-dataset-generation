WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(co.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        MIN(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS FirstChangeDate,
        COUNT(ph.Comment) FILTER (WHERE ph.Comment IS NOT NULL) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate < (CURRENT_DATE - INTERVAL '1 month')
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    ur.MaxReputation,
    COALESCE(phd.FirstChangeDate, 'No Changes') AS FirstChangeDate,
    COUNT(DISTINCT CASE WHEN phd.EditCount > 0 THEN phd.UserId END) AS DistinctEditors,
    STRING_AGG(DISTINCT CASE WHEN t.TagName IS NOT NULL THEN t.TagName ELSE 'Unknown' END, ', ') AS TagsUsed
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = rp.PostId
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    PostsTags pt ON rp.PostId = pt.PostId   -- Assuming PostsTags is a junction table you might define
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    rp.ScoreRank <= 10 AND 
    (u.Reputation IS NULL OR u.Reputation > 100) AND 
    (phd.FirstChangeDate IS NULL OR phd.FirstChangeDate > (CURRENT_DATE - INTERVAL '6 months'))
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, ur.MaxReputation, phd.FirstChangeDate
ORDER BY 
    rp.Score DESC;
