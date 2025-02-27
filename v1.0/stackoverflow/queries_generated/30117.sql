WITH RecursivePosts AS (
    SELECT 
        Id, 
        Title, 
        OwnerUserId, 
        CreationDate,
        Score,
        ViewCount,
        AcceptedAnswerId,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes,
        (SELECT COUNT(DISTINCT c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(DISTINCT ph.Id) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)) AS CloseOpenCount
    FROM 
        RecursivePosts p
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
)
SELECT 
    ps.Id AS PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    ub.BadgeCount,
    RANK() OVER (PARTITION BY ub.BadgeCount ORDER BY ps.Score DESC) AS ScoreRank,
    CASE 
        WHEN ps.CloseOpenCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN ps.ViewCount IS NULL THEN 'No Views' 
        ELSE 'Viewed'
    END AS ViewStatus
FROM 
    PostStats ps
LEFT JOIN 
    UserBadges ub ON ps.OwnerUserId = ub.UserId
WHERE 
    ps.Score > 0 -- Only posts with score greater than 0
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC;
