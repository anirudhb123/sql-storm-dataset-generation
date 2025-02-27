WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ViewCount > 1000
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        pt.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
    HAVING 
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) > 0
)

SELECT 
    rp.Title,
    rp.Score,
    rp.CreationDate,
    cp.CloseDate,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    mau.DisplayName AS MostActiveUser,
    mau.VoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
LEFT JOIN 
    MostActiveUsers mau ON mau.UserId IN (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = rp.Id
    )
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC;
