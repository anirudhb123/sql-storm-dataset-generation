
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
TopUserPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(*) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
    GROUP BY 
        rp.OwnerDisplayName
),
UserBadges AS (
    SELECT
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN b.Id END) AS Gold,
        COUNT(CASE WHEN b.Class = 2 THEN b.Id END) AS Silver,
        COUNT(CASE WHEN b.Class = 3 THEN b.Id END) AS Bronze
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ub.DisplayName,
    COALESCE(tp.PostCount, 0) AS PostCount,
    COALESCE(tp.TotalScore, 0) AS TotalScore,
    COALESCE(tp.AvgViewCount, 0) AS AvgViewCount,
    ub.Gold,
    ub.Silver,
    ub.Bronze
FROM 
    UserBadges ub
LEFT JOIN 
    TopUserPosts tp ON ub.DisplayName = tp.OwnerDisplayName
ORDER BY 
    TotalScore DESC, 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
