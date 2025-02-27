WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rv.TotalVotes,
    rv.UpVotes,
    rv.DownVotes,
    tu.DisplayName AS TopUser,
    tu.Reputation
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
WHERE 
    rp.Rank <= 5
    AND (rv.UpVotes IS NOT NULL OR rv.DownVotes IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;

-- Further exploration for closed posts
WITH ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    cp.Id,
    cp.Title,
    cp.CreationDate,
    cp.Comment,
    cp.UserDisplayName
FROM 
    ClosedPosts cp
WHERE 
    cp.UserDisplayName IS NOT NULL
ORDER BY 
    cp.CreationDate DESC;
