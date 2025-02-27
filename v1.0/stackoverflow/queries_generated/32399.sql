WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        DISTINCT p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    up.UpVotes,
    down.DownVotes,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    cp.LastClosedDate,
    rp.ScoreRank,
    rp.RecentRank
FROM 
    RankedPosts rp
JOIN 
    PostVoteSummary up ON rp.PostId = up.PostId
JOIN 
    PostVoteSummary down ON rp.PostId = down.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.RecentRank ASC;
