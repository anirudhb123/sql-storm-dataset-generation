WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers
),
RankedPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.OwnerUserId,
        RANK() OVER (PARTITION BY r.OwnerUserId ORDER BY r.Score DESC) AS UserRank
    FROM 
        RecursiveCTE r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(cp.CloseCount, 0) AS ClosedCount,
    rp.UserRank,
    CASE 
        WHEN rp.UserRank = 1 THEN 'Top Post'
        WHEN rp.UserRank <= 5 THEN 'Featured Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
INNER JOIN 
    Posts p ON rp.PostId = p.Id
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary ps ON p.Id = ps.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts within last 30 days
ORDER BY 
    rp.UserRank, ps.VoteCount DESC, p.CreationDate DESC;
