WITH UserVoteDetails AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(v.Id) AS TotalVotes, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
PostTagDetails AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags,2,length(p.Tags)-2), '><')) AS Tag
    FROM Posts p
    WHERE p.PostTypeId = 1
),
TagUsage AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM PostTagDetails
    GROUP BY Tag
),
QualifiedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate,
        uv.TotalVotes,
        uv.UpVotes,
        uv.DownVotes,
        uv.Favorites
    FROM Users u
    JOIN UserVoteDetails uv ON u.Id = uv.UserId
    WHERE u.Reputation > 1000 -- Threshold for qualified users
)
SELECT 
    q.UserId,
    q.DisplayName,
    q.Reputation,
    q.CreationDate,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    t.Tag,
    tu.UsageCount
FROM QualifiedUsers q
JOIN Votes v ON q.UserId = v.UserId
JOIN Posts p ON v.PostId = p.Id
JOIN PostTagDetails ptd ON p.Id = ptd.PostId
JOIN TagUsage tu ON ptd.Tag = tu.Tag
JOIN TopPosts tp ON p.Id = tp.PostId
WHERE tp.PostRank <= 10 -- Filter for top 10 posts
ORDER BY q.Reputation DESC, tp.Score DESC, tu.UsageCount DESC;
