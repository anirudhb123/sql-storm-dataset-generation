WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        PostCount,
        CommentCount,
        RANK() OVER (ORDER BY PostCount DESC, NetVotes DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.CommentCount,
    tu.NetVotes,
    ROW_NUMBER() OVER (PARTITION BY tu.Rank ORDER BY tu.CommentCount DESC) AS RankPosition
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, tu.CommentCount DESC;
