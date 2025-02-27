WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT ph.Comment || ' (' || ph.CreationDate::text || ')', '; ') AS HistoryDetails
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted
    GROUP BY 
        ph.PostId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    COALESCE(rb.BadgeCount, 0) AS BadgeCount,
    COALESCE(rb.BadgeNames, 'No Badges') AS BadgeNames,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    pc.CommentCount,
    ph.HistoryCount,
    ph.HistoryDetails, 
    CASE 
        WHEN ph.HistoryCount > 0 THEN 
            CASE 
                WHEN MAX(ph.PostHistoryTypeId) IN (10, 12) THEN 'Post Closed/Deleted' 
                ELSE 'Active Post' 
            END
        ELSE 'No History Available'
    END AS PostStatus
FROM 
    Users up
LEFT JOIN 
    UserBadges rb ON up.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    up.Reputation > 100
ORDER BY 
    up.DisplayName ASC, 
    rp.PostCreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; 
