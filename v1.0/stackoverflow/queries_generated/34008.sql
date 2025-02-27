WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    ub.BadgeCount,
    ISNULL(cp.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    CASE 
        WHEN ub.BadgeCount > 10 THEN 'Expert'
        ELSE 'Novice'
    END AS UserExpertise
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC,
    ub.BadgeCount DESC;
