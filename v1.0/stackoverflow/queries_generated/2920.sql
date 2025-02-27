WITH UserReputation AS (
    SELECT u.Id AS UserId, 
           u.Reputation,
           RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
RecentPosts AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId,
           MAX(p.CreationDate) AS LatestPostDate
    FROM Posts p
    WHERE p.CreationDate >= current_date - interval '30 days'
    GROUP BY p.Id, p.OwnerUserId
),
PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           COALESCE(v.UpVotes, 0) AS UpVotes,
           COALESCE(v.DownVotes, 0) AS DownVotes,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, 
               COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>,<')) AS tag ON true
    LEFT JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id, p.Title, p.ViewCount
),
BenchmarkData AS (
    SELECT ur.UserId,
           ur.Reputation,
           pp.PostId,
           pp.Title,
           pp.ViewCount,
           pp.UpVotes,
           pp.DownVotes,
           pp.CommentCount,
           pp.Tags,
           ROW_NUMBER() OVER (PARTITION BY ur.Reputation ORDER BY pp.ViewCount DESC) AS RankWithinReputation
    FROM UserReputation ur
    JOIN RecentPosts rp ON ur.UserId = rp.OwnerUserId
    JOIN PostDetails pp ON pp.PostId = rp.PostId
)

SELECT b.UserId, 
       b.Reputation, 
       b.PostId, 
       b.Title, 
       b.ViewCount, 
       b.UpVotes, 
       b.DownVotes,
       b.CommentCount,
       b.Tags,
       b.RankWithinReputation
FROM BenchmarkData b
WHERE b.RankWithinReputation <= 5
ORDER BY b.Reputation DESC, b.ViewCount DESC;
