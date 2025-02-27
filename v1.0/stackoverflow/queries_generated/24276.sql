WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened types
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.MaxReputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(cp.FirstClosedDate, 'No Closure') AS ClosureDate,
    us.Questions,
    us.Answers,
    us.UpVotes,
    us.DownVotes
FROM 
    UserStatistics us
JOIN 
    Users up ON us.UserId = up.Id
LEFT JOIN 
    RankedPosts rp ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    us.Questions > 5 
    AND us.MaxReputation > 1000
ORDER BY 
    us.MaxReputation DESC,
    rp.Score DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

-- Additional corner cases and checks
SELECT 
    p.Id,
    p.Title,
    p.Body,
    CASE 
        WHEN ph.CreationDate IS NULL THEN 'No History' 
        ELSE 'Has History' 
    END AS HistoryStatus,
    (SELECT STRING_AGG(DISTINCT ct.Name, ', ' ORDER BY ct.Name) 
     FROM CloseReasonTypes ct 
     JOIN PostHistory ph ON ph.Comment::int = ct.Id 
     WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10) AS CloseReasons
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.ViewCount IS NOT NULL 
    AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
    AND p.Title NOT LIKE '%[Duplicate]%'
ORDER BY 
    p.ViewCount DESC, 
    p.CreationDate DESC;

