WITH RECURSIVE UserReputation AS (
    -- CTE to calculate cumulative reputation for users
    SELECT 
        Id,
        Reputation,
        CreationDate,
        Views,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), RecentPosts AS (
    -- CTE to get recent posts along with their tags and related information
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        string_agg(t.TagName, ', ') AS Tags,
        COALESCE( COUNT(c.Id), 0) AS CommentCount,
        COALESCE( COUNT(v.Id), 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id
), PopularTags AS (
    -- CTE to find the most popular tags based on recent posts
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    ur.Id AS UserId,
    ur.Reputation,
    ur.Views,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.CommentCount,
    rp.VoteCount,
    pt.TagName AS PopularTag
FROM UserReputation ur
LEFT JOIN RecentPosts rp ON ur.Id = rp.OwnerUserId
LEFT JOIN PopularTags pt ON pt.TagName = ANY (string_to_array(rp.Tags, ', '))
WHERE ur.Reputation > 1000 -- Filter for highly reputed users
  AND (rp.CommentCount > 5 OR rp.VoteCount > 10) -- Criteria for active posts
  AND rp.PostRank <= 3 -- Limit to top 3 posts per user
ORDER BY ur.Reputation DESC, rp.Score DESC;
