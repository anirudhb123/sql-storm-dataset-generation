WITH UserVotes AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = p.Id
    WHERE t.Count > 0
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
    ORDER BY p.Score DESC, UpVoteCount DESC
    LIMIT 5
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.UpVotes,
    u.DownVotes,
    pt.TagName,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate
FROM UserVotes u
CROSS JOIN PopularTags pt
JOIN TopPosts tp ON tp.PostId = ANY(SELECT PostId FROM Posts WHERE Tags LIKE '%' || pt.TagName || '%')
ORDER BY u.UpVotes DESC, tp.Score DESC;
