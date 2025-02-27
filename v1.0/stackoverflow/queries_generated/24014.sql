WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE((
            SELECT SUM(vt.Reputation)
            FROM Votes v
            JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
            WHERE v.PostId = p.Id
            AND vt.Name IN ('UpMod', 'BountyStart')
        ), 0) AS TotalUpvotes,
        COALESCE((
            SELECT SUM(vt.Reputation)
            FROM Votes v
            JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
            WHERE v.PostId = p.Id
            AND vt.Name = 'DownMod'
        ), 0) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgesCount,
        STRING_AGG(b.Name, ', ') AS AwardedBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        COALESCE(cr.Name, 'Not specified') AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Post Closed
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
),

PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.TotalUpvotes,
        rp.TotalDownvotes,
        up.UserId AS OwnerId,
        ub.BadgesCount,
        ub.AwardedBadges,
        COALESCE(cp.ClosedDate, 'Not Closed') AS ClosureDate,
        cp.CloseReason
    FROM 
        RankedPosts rp
    JOIN 
        Users up ON up.Id = (
            SELECT OwnerUserId 
            FROM Posts WHERE Id = rp.PostId
        )
    LEFT JOIN 
        UserBadges ub ON up.Id = ub.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.Id
)

SELECT 
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    COALESCE(ps.BadgesCount, 0) AS TotalBadges,
    ps.AwardedBadges,
    ps.ClosureDate,
    ps.CloseReason,
    LEAD(ps.Score) OVER (ORDER BY ps.Score DESC) AS NextScoreInRank
FROM 
    PostSummary ps
WHERE 
    (ps.ClosureDate IS NULL OR ps.ClosureDate > NOW() - INTERVAL '1 month')
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;

