WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS TotalScore,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 1 THEN v.UserId END) AS AcceptedCount,
        MAX(p.CreationDate) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (NOW() - INTERVAL '1 year') 
        AND (p.Score IS NOT NULL OR p.ViewCount > 0)
    GROUP BY p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.VoteScore,
        ps.AcceptedCount,
        RANK() OVER (ORDER BY ps.VoteScore DESC, ps.CommentCount DESC) AS Rank
    FROM PostStats ps
)
SELECT 
    tps.Title,
    uvs.DisplayName,
    tps.VoteScore AS TotalVotes,
    tps.CommentCount,
    tps.AcceptedCount,
    CASE
        WHEN tps.VoteScore > 0 THEN 'Popular'
        WHEN tps.VoteScore < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS VoteCategory,
    COALESCE(tps.LastActivity, 'No Activity') AS LastActivity
FROM TopPosts tps
JOIN UserVoteSummary uvs ON uvs.TotalVotes > 0
WHERE tps.Rank <= 10
ORDER BY tps.VoteScore DESC, tps.CommentCount DESC;
