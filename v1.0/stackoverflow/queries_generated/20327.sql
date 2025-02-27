WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS Upvotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS Downvotes,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),

ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
    GROUP BY 
        ph.PostId
)

SELECT 
    u.DisplayName,
    ub.BadgeCount AS TotalBadges,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.TotalBounty,
    COALESCE(ch.LastClosedDate, 'Never Closed') AS LastClosedDate,
    COALESCE(ch.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    UserBadges ub
JOIN 
    Users u ON u.Id = ub.UserId
LEFT JOIN 
    PostStatistics ps ON ps.CommentCount > 0
LEFT JOIN 
    ClosedPostHistory ch ON ps.PostId = ch.PostId
WHERE 
    ub.BadgeCount > 0 -- Users must have at least one badge
ORDER BY 
    ub.BadgeCount DESC, 
    ps.Upvotes DESC
LIMIT 100;
