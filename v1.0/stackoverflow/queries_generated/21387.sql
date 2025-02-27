WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        STUFF((SELECT ',' + TagName 
               FROM Tags t 
               WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int) 
               ORDER BY TagName
               FOR XML PATH('')), 1, 1, '') AS ParsedTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.Tags
),

PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        p.Title AS PostTitle,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
),

BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        B.Name AS BadgeName,
        COUNT(B.Id) AS BadgeCount,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Badges B ON u.Id = B.UserId
    GROUP BY 
        u.Id, u.DisplayName, B.Name, u.Reputation
    HAVING 
        COUNT(B.Id) >= 1
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ParsedTags,
    phd.EditCount,
    CASE 
        WHEN bu.UserId IS NOT NULL THEN bu.DisplayName 
        ELSE 'No badge owner' 
    END AS BadgeOwner,
    CASE 
        WHEN bu.BadgeCount IS NOT NULL THEN bu.BadgeCount
        ELSE 0 
    END AS TotalBadges,
    CASE 
        WHEN phd.PostHistoryTypeId IS NOT NULL THEN COUNT(phd.UserId)
        ELSE 0 
    END AS TotalEdits
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryData phd ON rp.PostId = phd.PostId
LEFT JOIN 
    BadgedUsers bu ON bu.UserId = rp.PostId
WHERE 
    (rp.Score > 0 OR phd.PostHistoryTypeId IS NULL)
    AND (rp.ParsedTags LIKE '%SQL%' OR rp.ParsedTags LIKE '%Database%')
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ParsedTags, phd.EditCount, bu.UserId, bu.DisplayName, bu.BadgeCount, phd.PostHistoryTypeId
ORDER BY 
    rp.Score DESC NULLS LAST, TotalBadges DESC;

