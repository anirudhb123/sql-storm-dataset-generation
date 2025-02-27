WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(COUNT(v.UserId) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(COUNT(v.UserId) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(rp.UpVotes - rp.DownVotes) > 10
),
PostHistories AS (
    SELECT 
        ph.PostId,
        string_agg(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChanged
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    th.ChangeCount AS HistoricalChanges,
    th.HistoryTypes,
    tu.NetVotes
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    PostHistories th ON rp.PostId = th.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.ViewCount DESC, 
    tu.NetVotes DESC
LIMIT 50;

-- Adding edge cases where NULL handling is crucial
-- If a user has no votes, consider them with zero net votes
-- If a post has no history, still select the record with null or empty history types
