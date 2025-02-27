WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rank,
        COALESCE((SELECT COUNT(*) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
), UserBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(b.Name) AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    up.Id,
    up.Title,
    up.CreationDate,
    up.ViewCount,
    up.Score,
    up.CommentCount,
    COALESCE(ub.BadgeNames, '{}') AS BadgeNames,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN up.rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    RankedPosts up
LEFT JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
LEFT JOIN 
    PostVoteStats pvs ON up.Id = pvs.PostId
WHERE 
    up.rank <= 5
ORDER BY 
    up.Score DESC, up.ViewCount DESC;
