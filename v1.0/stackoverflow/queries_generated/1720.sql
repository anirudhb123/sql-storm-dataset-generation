WITH ActiveUsers AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
    WHERE LastAccessDate >= CURRENT_DATE - INTERVAL '1 year'
), RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.OwnerUserId, p.Tags,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Tags
), PopularTags AS (
    SELECT UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM Posts
    WHERE Tags IS NOT NULL
), UserPostStats AS (
    SELECT u.Id AS UserId, u.DisplayName, COUNT(rp.PostId) AS PostCount,
           AVG(rp.UpVotes - rp.DownVotes) AS AvgScore
    FROM ActiveUsers u
    LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT u.DisplayName, u.Reputation, ups.PostCount, ups.AvgScore, 
       ARRAY_AGG(DISTINCT pt.Tag) AS PopularTags
FROM UserPostStats ups
JOIN ActiveUsers u ON ups.UserId = u.Id
JOIN PopularTags pt ON pt.Tag IN (SELECT UNNEST(string_to_array(ANY(RecentPosts.Tags), '><')) FROM RecentPosts)
WHERE ups.PostCount > 5
GROUP BY u.DisplayName, u.Reputation, ups.PostCount, ups.AvgScore
ORDER BY u.Reputation DESC;
