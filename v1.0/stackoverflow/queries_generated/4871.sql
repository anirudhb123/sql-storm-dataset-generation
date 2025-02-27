WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0
), UserBadges AS (
    SELECT 
        u.Id as UserId, 
        COUNT(b.Id) as BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
), PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) as ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) as ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id,
    p.Title,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    phd.ClosedDate,
    phd.ReopenedDate,
    rnd.Score,
    rnd.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    RankedPosts rnd ON p.Id = rnd.Id
LEFT JOIN 
    UserBadges pb ON p.OwnerUserId = pb.UserId
LEFT JOIN 
    PostHistoryDetails phd ON p.Id = phd.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    rnd.rn = 1 -- Only top-ranked questions per user
GROUP BY 
    p.Id, rnd.Score, rnd.ViewCount, pb.BadgeCount, phd.ClosedDate, phd.ReopenedDate
ORDER BY 
    p.CreationDate DESC
LIMIT 50;
