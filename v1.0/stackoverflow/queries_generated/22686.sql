WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.Text,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (SELECT MIN(CreationDate) FROM PostHistory)
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
ClosedPostInfo AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserBadgeCount AS (
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
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(pc.CloseDate, 'No closure record') AS LastCloseDate,
    COALESCE(pc.CloseReasons, 'N/A') AS CloseReasons,
    CASE 
        WHEN ub.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Ranking
FROM 
    Users u
LEFT JOIN 
    UserVoteSummary vs ON u.Id = vs.UserId
LEFT JOIN 
    ClosedPostInfo pc ON EXISTS (
        SELECT 1 
        FROM Posts p
        WHERE p.OwnerUserId = u.Id 
        AND p.Id = pc.PostId
        LIMIT 1
    )
LEFT JOIN 
    UserBadgeCount ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 100 
    AND (u.Location IS NULL OR u.Location LIKE '%USA%')
    AND (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) >= 5
ORDER BY 
    Ranking, u.DisplayName;
