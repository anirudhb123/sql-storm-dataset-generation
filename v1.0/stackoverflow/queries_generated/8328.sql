WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN bp.PostRank = 1 THEN 1 ELSE 0 END) AS TopPostCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    JOIN 
        RankedPosts bp ON u.Id = bp.OwnerUserId
    WHERE 
        bp.PostRank <= 5
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.TopPostCount,
    tu.AverageReputation
FROM 
    TopUsers tu
ORDER BY 
    tu.TopPostCount DESC, 
    tu.AverageReputation DESC
LIMIT 10;
