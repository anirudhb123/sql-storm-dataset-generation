WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation,
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    GROUP BY TagName
    HAVING COUNT(*) > 5
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    pt.TagName,
    pw.UpVotes,
    pw.DownVotes,
    CASE 
        WHEN pw.UpVotes > pw.DownVotes THEN 'Positive'
        WHEN pw.UpVotes < pw.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM UserReputation u
LEFT JOIN RecentPosts rp ON u.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN TopTags pt ON pt.TagName IN (SELECT UNNEST(string_to_array(rp.Tags, '><')))
LEFT JOIN PostsWithVotes pw ON rp.PostId = pw.PostId
WHERE u.Reputation > 100
AND (rp.CreationDate IS NOT NULL OR rp.CreationDate < NOW() - INTERVAL '60 days')
ORDER BY u.Reputation DESC, rp.CreationDate DESC
LIMIT 50;
