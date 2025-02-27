WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.UpVotes) - SUM(rp.DownVotes) AS NetVote,
        RANK() OVER (ORDER BY SUM(rp.UpVotes) - SUM(rp.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(rp.Id) > 2
)
SELECT 
    tu.DisplayName,
    tu.NetVote,
    COUNT(DISTINCT rp.Id) AS PostsCount,
    STRING_AGG(DISTINCT p.Tags, ', ') AS PostTags
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
JOIN 
    Posts p ON rp.Id = p.Id
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.DisplayName, tu.NetVote
ORDER BY 
    tu.NetVote DESC;
