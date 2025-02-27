WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, CURRENT_TIMESTAMP)
),
RecentActivity AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        MAX(ph.CreationDate) AS LastActivityDate,
        STRING_AGG(DISTINCT pt.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= DATEADD(HOUR, -24, CURRENT_TIMESTAMP)
    GROUP BY 
        ph.UserId, ph.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS Owner,
    rp.ViewCount,
    rp.CreationDate,
    rp.Rank,
    rp.TotalPosts,
    ra.LastActivityDate,
    ra.HistoryTypes,
    COALESCE(pvs.TotalUpvotes, 0) AS Upvotes,
    COALESCE(pvs.TotalDownvotes, 0) AS Downvotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    (COALESCE(pvs.TotalUpvotes, 0) - COALESCE(pvs.TotalDownvotes, 0)) AS Score,
    CASE 
        WHEN ra.LastActivityDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.Rank = 1 
    AND (COALESCE(pvs.TotalUpvotes, 0) > 5 OR COALESCE(pvs.TotalDownvotes, 0) = 0)
ORDER BY 
    Score DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

