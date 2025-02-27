WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id
),
AggregatedVotes AS (
    SELECT 
        rp.PostId,
        (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
        CASE 
            WHEN rp.CommentCount > 5 THEN 'Active' 
            WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderate'
            ELSE 'Inactive'
        END AS ActivityLevel
    FROM 
        RankedPosts rp
)
SELECT 
    u.DisplayName AS User,
    COUNT(DISTINCT rp.PostId) AS PostCount,
    AVG(av.NetVotes) AS AverageNetVotes,
    MAX(av.ActivityLevel) AS HighestActivityLevel
FROM 
    Users u
INNER JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    AggregatedVotes av ON p.Id = av.PostId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    AverageNetVotes DESC, User
LIMIT 10;
