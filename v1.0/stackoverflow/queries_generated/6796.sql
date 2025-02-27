WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND p.Score > 0
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(*) > 5
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        mau.DisplayName AS ActiveUserDisplayName,
        mau.PostCount,
        mau.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MostActiveUsers mau ON rp.OwnerDisplayName = mau.DisplayName
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    ActiveUserDisplayName,
    PostCount,
    BadgeCount
FROM 
    CombinedData
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
