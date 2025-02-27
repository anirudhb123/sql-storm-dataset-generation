WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        COALESCE(u.Reputation, 0) AS UserReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TagData AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UserReputation,
        td.TagName,
        phd.UserId AS LastEditorId,
        phd.Comment AS LastEditComment,
        phd.CreationDate AS LastEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagData td ON rp.PostId = (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.Tags LIKE '%' || td.TagName || '%' 
            LIMIT 1
        )
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId AND phd.HistoryRank = 1
)
SELECT 
    f.*,
    CASE 
        WHEN f.LastEditDate IS NULL THEN 'No edits made'
        ELSE CONCAT('Last edited on ', TO_CHAR(f.LastEditDate, 'YYYY-MM-DD HH24:MI:SS'))
    END AS EditMessage,
    CASE 
        WHEN f.UserReputation > 1000 THEN 'High Reputation'
        WHEN f.UserReputation = 0 THEN 'New User'
        ELSE 'Regular User'
    END AS UserStatus
FROM 
    FinalResults f
WHERE 
    f.UserReputation IS NOT NULL
ORDER BY 
    f.Score DESC, f.LastEditDate DESC
LIMIT 10;

