WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = p.Tags
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName AS User,
    u.TotalVotes,
    u.UpVotes,
    u.DownVotes,
    tt.TagName,
    ap.Title AS ActivePost,
    ap.ViewCount,
    ap.Score,
    ap.CreationDate
FROM UserVoteStats u
CROSS JOIN TopTags tt
JOIN ActivePosts ap ON ap.Rank = 1
WHERE u.TotalVotes > 10
ORDER BY u.TotalVotes DESC, ap.ViewCount DESC;
