WITH UserBadges AS (
    SELECT UserId, COUNT(Id) AS TotalBadges
    FROM Badges
    WHERE Date > NOW() - INTERVAL '1 year'
    GROUP BY UserId
),
RecentPosts AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.CreationDate, p.Title, p.Score, p.ViewCount,
           ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '1 month'
),
PostVotes AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostHistoryAggregated AS (
    SELECT PostId, COUNT(Id) AS EditCount
    FROM PostHistory
    WHERE PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY PostId
),
PopularTags AS (
    SELECT Tags.TagName, SUM(Posts.Score) AS TotalScore
    FROM Tags
    JOIN Posts ON Tags.Id = ANY(string_to_array(substr(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    WHERE Posts.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY Tags.TagName
    ORDER BY TotalScore DESC
    LIMIT 10
)
SELECT u.DisplayName, u.Reputation, ub.TotalBadges, rp.Title, rp.CreationDate, 
       rp.Score AS PostScore, rp.ViewCount, pv.UpVotes, pv.DownVotes,
       pha.EditCount, pt.TagName, pt.TotalScore
FROM Users u
JOIN UserBadges ub ON u.Id = ub.UserId
JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
JOIN PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN PostHistoryAggregated pha ON rp.PostId = pha.PostId
JOIN PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(rp.Title, ' ')))
WHERE rp.rn = 1
ORDER BY u.Reputation DESC, rp.Score DESC
LIMIT 100;
