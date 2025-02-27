WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COALESCE(MAX(rp.Score), 0) AS MaxScore,
        COALESCE(SUM(pvs.UpvoteCount - pvs.DownvoteCount), 0) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        PostVoteStats pvs ON rp.Id = pvs.PostId
    GROUP BY 
        u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.MaxScore,
    tu.NetVotes,
    CASE 
        WHEN tu.Reputation > 1000 THEN 'Gold'
        WHEN tu.Reputation > 500 THEN 'Silver'
        ELSE 'Bronze' 
    END AS Badge
FROM 
    TopUsers tu
WHERE 
    tu.MaxScore > 0
ORDER BY 
    tu.NetVotes DESC NULLS LAST, 
    tu.MaxScore DESC
LIMIT 10;

SELECT 
    'Total Posts Created Last Year' AS Metric,
    COUNT(*) AS Value
FROM 
    Posts
WHERE 
    CreationDate >= NOW() - INTERVAL '1 year';

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS Count
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    Count DESC;
