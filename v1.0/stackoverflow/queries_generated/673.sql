WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(rp.Score) DESC) AS ReputationRank
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(rp.Score) > 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    COALESCE(rp.CommentCount, 0) AS RecentPostComments,
    COALESCE(rp.UpVotes, 0) AS RecentPostUpVotes,
    COALESCE(rp.DownVotes, 0) AS RecentPostDownVotes,
    CASE 
        WHEN tu.ReputationRank IS NULL THEN 'No Posts'
        ELSE DISTINCT 'Top Contributor'
    END AS ContributorStatus
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
ORDER BY 
    tu.ReputationRank;
