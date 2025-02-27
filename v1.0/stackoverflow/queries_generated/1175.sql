WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditedDate,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    up.PostId,
    up.Title,
    up.CreationDate,
    uh.FirstEditedDate,
    uh.EditCount,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.TotalVotes,
    COALESCE(pv.Rank, 'No Score') AS PostRank
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    PostHistoryInfo uh ON up.PostId = uh.PostId
LEFT JOIN 
    UserVoteStats uvs ON u.Id = uvs.UserId
LEFT JOIN 
    (SELECT 
         PostId, 
         DENSE_RANK() OVER (ORDER BY Score DESC) AS Rank 
     FROM 
         Posts) pv ON up.PostId = pv.PostId
WHERE 
    up.PostRank <= 3
    AND (uh.EditCount IS NULL OR uh.EditCount > 0)
ORDER BY 
    u.DisplayName, up.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
