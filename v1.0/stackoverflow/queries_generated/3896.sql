WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.Score, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score > 10
),
PostVoteSummary AS (
    SELECT PostId, COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY PostId
),
TagActivity AS (
    SELECT t.Id AS TagId, t.TagName, COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE p.CreationDate >= NOW() - INTERVAL '1 MONTH'
    GROUP BY t.Id
),
UserEngagement AS (
    SELECT u.Id, u.DisplayName,
           COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
           COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
           COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE u.Reputation > 100
    GROUP BY u.Id
)
SELECT u.DisplayName, u.Reputation, 
       COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
       COALESCE(rv.UpVotes, 0) AS TotalUpVotes,
       COALESCE(rv.DownVotes, 0) AS TotalDownVotes,
       ta.TagName, ta.PostCount
FROM Users u
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN PostVoteSummary rv ON rv.PostId = rp.Id
LEFT JOIN TagActivity ta ON ta.TagId IN (SELECT UNNEST(string_to_array(rp.Tags, ','))::int) -- Assuming Tags column has comma-separated Tag IDs
WHERE u.LastAccessDate >= NOW() - INTERVAL '6 MONTH'
ORDER BY u.Reputation DESC, TotalUpVotes DESC
LIMIT 50;
