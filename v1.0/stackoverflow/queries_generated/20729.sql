WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.Score >= 0 -- Non-negative score questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        SUM(COALESCE(p.UpVotes, 0) - COALESCE(p.DownVotes, 0)) AS NetVotes,
        AVG(EXTRACT(EPOCH FROM (NOW() - u.CreationDate)) / 86400) AS AvgDaysActive
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId, 
        ph.Comment,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10   -- Post Closed
    GROUP BY 
        ph.PostId, ph.Comment
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.BadgeCount,
        us.HighViewCountPosts,
        us.NetVotes,
        us.AvgDaysActive,
        rp.PostId,
        rp.Title,
        rp.Score,
        cp.CloseReasonCount,
        COALESCE(cp.Comment, 'No Close Reason') AS CloseReason
    FROM 
        UserStats us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    LEFT JOIN 
        ClosedPostReasons cp ON rp.PostId = cp.PostId
    WHERE 
        (us.BadgeCount > 5 OR us.NetVotes > 10)   -- Filter for notable users
)

SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.BadgeCount,
    fs.HighViewCountPosts,
    fs.NetVotes,
    fs.AvgDaysActive,
    fs.PostId,
    fs.Title,
    fs.Score,
    fs.CloseReasonCount,
    fs.CloseReason
FROM 
    FinalStats fs
WHERE 
    (fs.CloseReasonCount IS NULL OR fs.CloseReasonCount < 2)
ORDER BY 
    fs.NetVotes DESC,
    fs.BadgeCount DESC NULLS LAST
LIMIT 50;

-- Edge Cases Observed
-- 1. Users with no posts shown if they have badges
-- 2. Users with multiple closed posts shown with a single close reason only
-- 3. NULL logic used to display default value for close reason if none exists
