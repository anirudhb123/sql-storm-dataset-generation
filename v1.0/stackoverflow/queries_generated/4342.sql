WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT l.RelatedPostId) AS RelatedPostsCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN PostLinks l ON l.PostId = p.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.UpVotes,
        u.DownVotes,
        ps.PostCount,
        ROW_NUMBER() OVER (ORDER BY u.UpVotes DESC) AS UserRank
    FROM UserVoteSummary u
    JOIN (
        SELECT 
            OwnerUserId,
            COUNT(PostId) AS PostCount
        FROM Posts
        GROUP BY OwnerUserId
    ) ps ON u.UserId = ps.OwnerUserId
    WHERE u.UpVotes > 0
)
SELECT 
    tu.DisplayName,
    tu.UpVotes,
    tu.DownVotes,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    CASE 
        WHEN ps.Score IS NULL THEN 'No Score'
        ELSE ps.Score::text
    END AS ScoreDisplay,
    CASE 
        WHEN ps.ViewCount IS NULL THEN 'No Views'
        ELSE ps.ViewCount::text
    END AS ViewsDisplay
FROM TopUsers tu
LEFT JOIN PostStatistics ps ON tu.UserId = ps.PostId
WHERE tu.UserRank <= 10
ORDER BY tu.UpVotes DESC, tu.DownVotes ASC;
