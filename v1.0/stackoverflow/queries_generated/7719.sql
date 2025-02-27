WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5 -- Only users with at least 5 posts
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CreationDate,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.LastEditDate
FROM 
    TopUsers u
JOIN 
    RankedPosts tp ON u.UserId = tp.OwnerUserId AND tp.Rank <= 3
LEFT JOIN 
    PostHistorySummary ph ON tp.PostId = ph.PostId
ORDER BY 
    u.TotalScore DESC, tp.Score DESC
LIMIT 50;
