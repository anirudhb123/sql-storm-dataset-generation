
WITH UserVoteDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0)
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
    HAVING COUNT(v.Id) > 0
    ORDER BY p.Score DESC, p.ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    p.Title AS PostTitle,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    uv.DisplayName AS VoterName,
    uv.TotalVotes,
    uv.UpVotes,
    uv.DownVotes
FROM PopularPosts p
JOIN UserVoteDetails uv ON EXISTS (
    SELECT 1 FROM Votes WHERE PostId = p.PostId AND UserId = uv.UserId
)
ORDER BY p.Score DESC, uv.TotalVotes DESC;
