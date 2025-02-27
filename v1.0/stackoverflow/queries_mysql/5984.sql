
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        TotalVotes,
        UpVotes,
        DownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserVoteCounts, (SELECT @rank := 0) r
    WHERE 
        TotalVotes > 0
    ORDER BY 
        TotalVotes DESC
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS DownVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        @rank2 := @rank2 + 1 AS Rank
    FROM 
        PostStats ps, (SELECT @rank2 := 0) r
    WHERE 
        ps.UpVotes > 0 OR ps.CommentCount > 0
    ORDER BY 
        ps.UpVotes DESC, ps.CommentCount DESC
)
SELECT 
    tu.UserId,
    tu.TotalVotes,
    tu.UpVotes AS UserUpVotes,
    tu.DownVotes AS UserDownVotes,
    tp.PostId,
    tp.CommentCount,
    tp.UpVotes AS PostUpVotes,
    tp.DownVotes AS PostDownVotes
FROM 
    TopUsers tu
JOIN 
    TopPosts tp ON tu.UpVotes > tp.UpVotes
WHERE 
    tu.Rank <= 10 AND tp.Rank <= 10
ORDER BY 
    tu.TotalVotes DESC, tp.UpVotes DESC;
