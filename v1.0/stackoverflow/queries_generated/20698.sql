WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.ViewCount
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
), 
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed or Post Reopened
    GROUP BY 
        ph.PostId
), 
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.Reputation,
        u.BadgeCount,
        cp.LastClosedDate,
        cp.CloseVoteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation u ON rp.OwnerUserId = u.UserId
    LEFT JOIN 
        ClosedPostHistory cp ON rp.PostId = cp.PostId
    WHERE 
        rp.RecentPostRank <= 5 -- Only the 5 most recent posts by each user
)
SELECT 
    ps.Title AS PostTitle,
    ps.Reputation,
    COALESCE(ps.BadgeCount, 0) AS BadgeCount,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount,
    CASE 
        WHEN ps.CloseVoteCount IS NULL THEN 'No Close Votes'
        WHEN ps.CloseVoteCount > 0 THEN 'Closed with ' || ps.CloseVoteCount || ' votes'
        ELSE 'Not Closed'
    END AS CloseStatus,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.Reputation DESC, 
    ps.LastClosedDate DESC NULLS LAST
LIMIT 100;
