WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(ph.EditBody, 'No edits made') AS LastEditBody,
        ph.CreationDate AS LastEditDate,
        PHT.Name AS PostHistoryTypeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId 
            AND ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
    LEFT JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id 
    WHERE 
        rp.UserPostRank = 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tb.TotalBadges,
    tb.BadgeNames,
    COALESCE(tp.LastEditBody, 'No edits made.') AS LastEditBody,
    tp.LastEditDate,
    CASE 
        WHEN tp.LastEditDate IS NULL THEN 'Never Edited' 
        ELSE 'Edited' 
    END AS EditStatus
FROM 
    TopPosts tp
LEFT JOIN 
    UserBadges tb ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = tb.UserId)
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate ASC
LIMIT 100;
