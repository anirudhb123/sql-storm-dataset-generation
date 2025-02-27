WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        1 AS LinkDepth
    FROM 
        PostLinks pl
    WHERE 
        pl.LinkTypeId = 1  -- Linked posts

    UNION ALL

    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        rpl.LinkDepth + 1
    FROM 
        PostLinks pl
    JOIN 
        RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
    WHERE 
        pl.LinkTypeId = 1 AND rpl.LinkDepth < 5  -- Limit depth to avoid infinite recursion
),

PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        SUM( CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END ) AS TotalVoters
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

UserBadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

UserLocationSummary AS (
    SELECT 
        u.Location,
        COUNT(DISTINCT u.Id) AS UserCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    WHERE 
        u.Location IS NOT NULL
    GROUP BY 
        u.Location
),

PostClosureReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId in (10, 11)  -- Closed and reopened posts
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Title,
    p.CreationDate,
    ps.UpVotes,
    ps.DownVotes,
    pl.PostId AS LinkedPostId,
    u.DisplayName AS UserName,
    ub.BadgeCount,
    ul.UserCount AS LocationUserCount,
    ul.AvgReputation,
    PCR.CloseCount,
    PCR.CloseReasons
FROM 
    Posts p
LEFT JOIN 
    PostVoteSummary ps ON p.Id = ps.PostId
LEFT JOIN 
    RecursivePostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeCount ub ON u.Id = ub.UserId
LEFT JOIN 
    UserLocationSummary ul ON u.Location = ul.Location
LEFT JOIN 
    PostClosureReasons PCR ON p.Id = PCR.PostId
WHERE 
    (ps.UpVotes + ps.DownVotes) > 10  -- Only include posts with significant voting activity
    AND (p.CreationDate < NOW() - INTERVAL '1 year' OR p.ViewCount > 1000)  -- Include older or popular posts
ORDER BY 
    ps.UpVotes DESC, 
    p.CreationDate DESC
LIMIT 100;
