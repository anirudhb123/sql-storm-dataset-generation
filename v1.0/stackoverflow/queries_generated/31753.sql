WITH RecursiveCTE AS (
    SELECT 
        Id,
        OwnerUserId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        1 AS Depth
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        Depth + 1
    FROM 
        Posts p
    JOIN 
        RecursiveCTE r ON p.ParentId = r.Id
),
UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed Posts
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostDate,
    COALESCE(u.DisplayName, 'Anonymous') AS UserName,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(b.BadgeNames, 'None') AS UserBadges,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    cp.FirstClosedDate,
    cp.CloseReasonCount,
    RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
    ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS GlobalPostRank,
    COALESCE(r.Depth, 1) AS QuestionDepth
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostVoteSummary ps ON p.Id = ps.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
LEFT JOIN 
    RecursiveCTE r ON p.Id = r.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    AND (COALESCE(cp.CloseReasonCount, 0) = 0 OR cp.FirstClosedDate < NOW() - INTERVAL '30 days') -- Not closed recently
ORDER BY 
    p.Score DESC, 
    p.CreationDate ASC;
