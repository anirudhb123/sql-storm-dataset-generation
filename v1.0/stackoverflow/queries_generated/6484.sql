WITH RankedPost AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) AND 
        p.Score > 0
), 
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPost rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT Id FROM Users WHERE DisplayName = rp.OwnerDisplayName)
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.OwnerDisplayName,
    pwb.CreationDate,
    pwb.Score,
    pwb.ViewCount,
    pwb.BadgeCount,
    CASE 
        WHEN pwb.BadgeCount > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus
FROM 
    PostWithBadges pwb
ORDER BY 
    pwb.ViewCount DESC, 
    pwb.Score DESC;
