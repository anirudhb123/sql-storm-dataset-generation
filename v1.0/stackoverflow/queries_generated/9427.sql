WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS UserRank
    FROM UserVoteStats
)
SELECT
    pu.DisplayName AS TopUser,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount
FROM TopUsers pu
JOIN PostStats ps ON ps.UpVoteCount > 0
WHERE pu.UserRank <= 10
ORDER BY pu.UserRank, ps.UpVoteCount DESC;
