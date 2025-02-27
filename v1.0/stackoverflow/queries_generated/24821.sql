WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= DATEADD(year, -5, GETDATE()) 
        AND p.PostTypeId = 1 -- Only Questions
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM Votes v
    WHERE v.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(b.Class) > 5 -- Users with more than 5 badges
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(rv.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(rv.DownVotesCount, 0) AS DownVotesCount,
    u.DisplayName AS OwnerDisplayName,
    RANK() OVER (ORDER BY rp.ViewCount DESC, rp.CreationDate) AS ViewRank,
    CASE 
        WHEN cp.CloseReasons IS NOT NULL THEN 'Closed: ' || cp.CloseReasons 
        ELSE 'Active'
    END AS PostStatus,
    tu.TotalBadges,
    tu.TotalPosts
FROM RankedPosts rp
LEFT JOIN RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN TopUsers tu ON u.Id = tu.UserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.rn = 1 -- Get the top post for each user
ORDER BY rp.CreationDate DESC, ViewRank;
