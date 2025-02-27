
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.PostCount,
        u.PositivePosts,
        u.NegativePosts,
        u.TotalUpVotes,
        u.TotalDownVotes,
        FLOOR((@row_number := @row_number + 1) / (SELECT COUNT(*) FROM UserStats) * 5) AS UserRank
    FROM 
        UserStats u,
        (SELECT @row_number := 0) AS init
    WHERE 
        u.PostCount > 0
),
LatestPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        u.DisplayName AS OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.PostTypeId,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.PostCount,
    tu.PositivePosts,
    tu.NegativePosts,
    lp.Title AS LatestPostTitle,
    lp.CreationDate AS PostCreationDate,
    lp.Score AS PostScore
FROM 
    TopUsers tu
LEFT JOIN 
    LatestPosts lp ON tu.UserId = lp.OwnerUserId
WHERE 
    tu.UserRank = 1 
ORDER BY 
    tu.TotalUpVotes DESC, 
    lp.CreationDate DESC;
