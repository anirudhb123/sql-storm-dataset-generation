WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.PostTypeId = 1 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    CASE 
        WHEN uc.UserId IS NOT NULL THEN uc.TotalReputation
        ELSE 0 
    END AS UserReputation,
    COALESCE(phc.HistoryCount, 0) AS PostHistoryEntryCount,
    rp.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation uc ON rp.OwnerUserId = uc.UserId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC
