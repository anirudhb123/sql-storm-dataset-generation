WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatus AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastActionDate,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' 
                        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened' 
                        ELSE 'Active' END, ', ') AS Status
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.VoteCount,
    ub.BadgeCount,
    ps.Status,
    ps.LastActionDate
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.UserPostRank
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostStatus ps ON rp.PostId = ps.PostId
WHERE 
    (ub.BadgeCount > 0 OR ps.Status LIKE '%Closed%')
    AND rp.UserPostRank <= 5
ORDER BY 
    ub.BadgeCount DESC, 
    rp.Score DESC;
