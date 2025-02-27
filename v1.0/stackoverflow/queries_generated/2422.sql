WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalUpvotes,
        TotalDownvotes,
        PostCount,
        RANK() OVER (ORDER BY Reputation DESC, TotalUpvotes DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(rp.Title, 'No Posts') AS LatestPost,
    COALESCE(rp.CreationDate, 'N/A') AS LatestPostDate,
    tu.TotalUpvotes, 
    tu.TotalDownvotes,
    tu.PostCount
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.Reputation DESC, tu.TotalUpvotes DESC;
