
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        AvgPostScore,
        DENSE_RANK() OVER (ORDER BY TotalVotes DESC) AS Rank
    FROM 
        UserVoteStats
)

SELECT 
    tu.DisplayName,
    tu.TotalVotes,
    tu.UpVotes,
    tu.DownVotes,
    tu.AvgPostScore,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId 
LEFT JOIN 
    (SELECT 
        p.Id, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName 
     FROM 
        Posts p 
     INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON t.Id = p.Id
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.DisplayName, tu.TotalVotes, tu.UpVotes, tu.DownVotes, tu.AvgPostScore, tu.Rank
ORDER BY 
    tu.Rank;
