WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(v.VoteTypeId IN (2, 3)) AS TotalVotes, -- 2 for upvotes, 3 for downvotes
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CAST(ph.CreationDate AS VARCHAR), ', ') AS ClosedDateList
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    tu.TotalVotes AS UserTotalVotes,
    tu.TotalPosts AS UserTotalPosts,
    cp.ClosedDateList
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.OwnerPostRank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
