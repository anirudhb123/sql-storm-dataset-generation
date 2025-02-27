WITH UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > 1000
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        pt.Name AS PostType
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId
    LEFT JOIN Votes v ON p.Id = v.PostId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, pt.Name
),
UserTopPosts AS (
    SELECT 
        ur.Id AS UserId,
        us.DisplayName,
        ps.PostId,
        ps.Title,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CommentCount,
        ps.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY ur.Id ORDER BY ps.UpVoteCount DESC, ps.CommentCount DESC) as Rank
    FROM UserReputation ur
    JOIN Posts ps ON ps.OwnerUserId = ur.Id
    JOIN Users us ON us.Id = ur.Id
)
SELECT 
    utp.UserId,
    utp.DisplayName,
    utp.PostId,
    utp.Title,
    utp.UpVoteCount,
    utp.DownVoteCount,
    utp.CommentCount,
    utp.AnswerCount
FROM UserTopPosts utp
WHERE utp.Rank <= 5
ORDER BY utp.UserId, utp.UpVoteCount DESC;
