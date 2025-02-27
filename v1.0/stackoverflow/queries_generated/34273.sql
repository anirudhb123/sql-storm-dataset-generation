WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId -- left join to include posts with no comments
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- filter recent posts
    GROUP BY 
        p.Id
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
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- filter for closed posts
    ORDER BY 
        ph.CreationDate DESC
),

RecentPostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        pl.CreationDate >= NOW() - INTERVAL '6 months' -- filter links created recently
)

SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ub.BadgeCount,
    ub.BadgeNames,
    cp.CloseReason,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    COALESCE(rp.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(rp.DownVoteCount, 0) AS TotalDownVotes,
    rpl.RelatedPostId,
    rpl.LinkType
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    RecentPostLinks rpl ON rp.PostId = rpl.PostId
WHERE 
    rp.rn = 1 -- only get the most recent post for each user
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

