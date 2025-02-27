WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(UPV.UpVotes, 0) AS UpVotes,
        COALESCE(DWN.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVotes FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) UPV ON p.Id = UPV.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS DownVotes FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) DWN ON p.Id = DWN.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseHistoryCount, 
        MAX(ph.CreationDate) AS LastCloseDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ctr.Id = CAST(ph.Comment AS INTEGER)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalPostScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    cp.CloseHistoryCount,
    cp.LastCloseDate,
    cp.CloseReasons,
    ua.UserId,
    ua.DisplayName,
    ua.TotalPostScore,
    ua.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserActivity ua ON ua.UserId = u.Id
WHERE 
    (rp.UpVotes - rp.DownVotes) > 5 
    AND (rp.TotalComments >= 2 OR cp.CloseHistoryCount IS NOT NULL)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC
FETCH FIRST 10 ROWS ONLY;

-- Here we have constructed a complex SQL query that incorporates various advanced SQL features:
-- 1. CTEs (Common Table Expressions) for modular and readable query design.
-- 2. Window functions to rank posts based on creation date.
-- 3. Aggregate functions to summarize votes and comments.
-- 4. String aggregation to collect a list of close reasons.
-- 5. Correlated subqueries to calculate total comments directly in the main selection.
-- 6. Complicated predicates combining several conditions to filter results.
-- 7. Outer joins to gather votes and comments even if some posts lack these records.
-- 8. Ordering and limiting results for refined output. 
