WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        CLOSE_REASON = CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No reason provided'
        END
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ub.BadgeCount,
        bp.ClosedDate,
        bp.CLOSE_REASON,
        CASE 
            WHEN bp.CLOSED IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        (SELECT PostId, MAX(CreationDate) AS ClosedDate, CLOSE_REASON FROM ClosedPosts GROUP BY PostId) bp ON rp.PostId = bp.PostId
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.BadgeCount,
    fp.ClosedDate,
    fp.CLOSE_REASON,
    fp.PostStatus,
    COALESCE((SELECT AVG(CAST(v.BountyAmount AS FLOAT)) 
               FROM Votes v 
               WHERE v.PostId = fp.PostId AND v.VoteTypeId = 8), 0) AS AverageBounty
FROM 
    FilteredPosts fp
WHERE 
    fp.BadgeCount > 0
ORDER BY 
    fp.Score DESC, 
    fp.PostStatus DESC;
