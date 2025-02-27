WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
),
UsersWithBadges AS (
    SELECT 
        u.Id,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Id, 
    rp.Title, 
    rp.CreationDate, 
    rp.ViewCount, 
    rp.Score, 
    rp.OwnerDisplayName, 
    rp.Rank,
    COALESCE(cp.CloseDate, 'No Closure') AS CloseDate,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    ub.BadgeCount AS UserBadgeCount,
    (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
JOIN 
    UsersWithBadges ub ON rp.OwnerDisplayName = ub.Id
WHERE 
    (rp.UPVoteCount - rp.DownVoteCount) > 5
    OR (CloseReason IS NOT NULL)
ORDER BY 
    NetVotes DESC, 
    rp.CreationDate DESC
LIMIT 50;
