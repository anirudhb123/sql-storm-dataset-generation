
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 90 DAY
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 10
), 
PostStats AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes, 
        @row_number:=@row_number + 1 AS Ranking,
        (SELECT COUNT(*) FROM RecentPosts) AS TotalPosts
    FROM 
        RecentPosts rp, (SELECT @row_number := 0) AS t
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.CreationDate, 
    ps.OwnerDisplayName, 
    ps.CommentCount, 
    ps.UpVotes, 
    ps.DownVotes, 
    ps.Ranking, 
    ps.TotalPosts, 
    tu.DisplayName AS TopVoter,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    PostStats ps
LEFT JOIN 
    TopUsers tu ON ps.OwnerDisplayName = tu.DisplayName
WHERE 
    ps.UpVotes > 0
ORDER BY 
    ps.Ranking;
