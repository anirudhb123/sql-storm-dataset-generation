WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10     -- Posts that have been closed
    GROUP BY 
        ph.PostId, ph.CreationDate
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        u.Id
),
EngagementMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(cp.CloseVotes, 0) AS CloseVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    em.PostId,
    em.Title,
    em.Score,
    em.UpVotes,
    em.DownVotes,
    em.CloseVotes,
    (em.UpVotes - em.DownVotes) AS NetScore,
    CASE 
        WHEN em.CloseVotes > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    au.DisplayName AS TopActiveUser
FROM 
    EngagementMetrics em
CROSS JOIN 
    (SELECT DisplayName FROM ActiveUsers ORDER BY PostsCount DESC LIMIT 1) au
WHERE 
    em.Rank <= 5
ORDER BY 
    em.PostStatus, em.Score DESC;
