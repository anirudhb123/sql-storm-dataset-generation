WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND p.OwnerUserId IS NOT NULL
), 
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 5)) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), 
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::INTEGER = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalBounty,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasonsDetails,
    CASE 
        WHEN rp.RecentPostRank = 1 THEN 'Most Recent Post'
        WHEN rp.RecentPostRank = 2 THEN 'Second Most Recent Post'
        ELSE 'Older Post'
    END AS PostAgeCategory,
    EXTRACT(EPOCH FROM NOW() - rp.CreationDate) AS AgeInSeconds
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.PostId = cpr.PostId
WHERE 
    pvs.UpVotes - pvs.DownVotes > 0
    AND rp.RecentPostRank <= 2  -- Only take the most recent posts
ORDER BY 
    pvs.UpVotes DESC, 
    rp.CreationDate ASC
LIMIT 10;

