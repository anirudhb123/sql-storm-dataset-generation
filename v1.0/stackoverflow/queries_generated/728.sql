WITH UserVoteStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostWithComments AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
)
SELECT
    p.Title,
    p.ViewCount,
    pcs.UserId,
    pcs.DisplayName,
    pcs.UpVotesCount,
    pcs.DownVotesCount,
    pcs.TotalVotes,
    pcs.NetVotes,
    pwc.CommentCount,
    CASE
        WHEN pwc.CommentCount > 5 THEN 'Hot Post'
        WHEN pwc.CommentCount <= 5 AND pwc.CommentCount > 0 THEN 'Moderate Activity'
        ELSE 'No Activity'
    END AS ActivityLevel
FROM UserVoteStatistics pcs
JOIN PostWithComments pwc ON pcs.UserId = pwc.PostId
WHERE pwc.rn = 1
AND (pcs.NetVotes > 0 OR (pcs.TotalVotes IS NULL AND pcs.DisplayName IS NOT NULL))
ORDER BY pwc.CommentCount DESC, pcs.NetVotes DESC
LIMIT 10;
