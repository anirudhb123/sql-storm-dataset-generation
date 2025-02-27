WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts AS p
    WHERE 
        p.Score > 0
        AND p.ViewCount IS NOT NULL
        AND p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
),
PostMetadata AS (
    SELECT 
        p.PostId,
        COALESCE(CAST(json_agg(DISTINCT b.Name) AS text), 'No Badges') AS BadgeNames,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        RankedPosts AS rp
    LEFT JOIN 
        Users AS u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges AS b ON b.UserId = u.Id
    LEFT JOIN 
        Comments AS c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes AS v ON v.PostId = rp.PostId
    GROUP BY 
        p.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastModificationDate,
        STRING_AGG(DISTINCT CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN cr.Name
            ELSE 'Other'
        END, ', ') AS CloseReasons
    FROM 
        PostHistory AS ph
    LEFT JOIN 
        CloseReasonTypes AS cr ON cr.Id::text = ph.Comment
    WHERE 
        ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    pm.BadgeNames,
    pm.CommentCount,
    pm.VoteCount,
    phd.LastModificationDate,
    phd.CloseReasons
FROM 
    RankedPosts AS rp
LEFT JOIN 
    PostMetadata AS pm ON pm.PostId = rp.PostId
LEFT JOIN 
    PostHistoryDetails AS phd ON phd.PostId = rp.PostId
WHERE 
    rp.Rnk = 1
    AND (pm.CommentCount > 5 OR pm.VoteCount > 10)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
