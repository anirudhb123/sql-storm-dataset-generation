WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostwithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rb.Name AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        (SELECT 
            UserId,
            STRING_AGG(Name, ', ') AS Name
        FROM 
            Badges
        WHERE 
            Date >= NOW() - INTERVAL '1 month'
        GROUP BY 
            UserId) rb ON b.UserId = rb.UserId
),
PostHistoryCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosedOrReopened
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.Score,
    pwb.BadgeName,
    phc.HistoryCount,
    phc.ClosedOrReopened,
    CASE 
        WHEN phc.ClosedOrReopened = 1 THEN 'Yes'
        ELSE 'No'
    END AS IsClosedOrReopened,
    CASE 
        WHEN pwb.Score IS NULL THEN 'No Score'
        ELSE CAST(pwb.Score AS VARCHAR)
    END AS ScoreDisplay,
    CASE 
        WHEN pwb.BadgeName IS NULL THEN 'No Badges'
        ELSE pwb.BadgeName
    END AS BadgeDisplay,
    RANK() OVER (ORDER BY pwb.Score DESC) AS GlobalRank
FROM 
    PostwithBadges pwb
JOIN 
    PostHistoryCounts phc ON pwb.PostId = phc.PostId
WHERE 
    (pwb.ViewCount > 100 OR pwb.Score IS NOT NULL OR phc.HistoryCount > 0)
AND 
    COALESCE(pwb.BadgeName, 'None') NOT LIKE '%Spam%'
ORDER BY 
    pwb.Score DESC, 
    pwb.CreationDate ASC
LIMIT 50;
