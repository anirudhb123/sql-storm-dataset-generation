WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        ph.Comment,
        ph.UserDisplayName,
        pt.Name AS PostTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
    JOIN 
        Posts p ON p.Id = ph.PostId
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        pht.Name = 'Post Closed'
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (NOW() - INTERVAL '30 days')
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    pv.UpVotes,
    pv.DownVotes,
    u.BadgeCount,
    u.BadgeNames,
    CAST(NULLIF(COALESCE(c.PostId, 0), 0) AS BOOLEAN) AS IsClosed,
    cp.UserDisplayName AS ClosedBy,
    cp.Comment AS ClosureReason
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pv ON rp.PostId = pv.PostId
LEFT JOIN 
    UserBadges u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ScoreRank <= 3
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
