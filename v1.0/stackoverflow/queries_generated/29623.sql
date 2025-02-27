WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
      AND p.CreationDate >= NOW() - INTERVAL '30 days' -- Questions from the last 30 days
),
PopularTags AS (
    SELECT
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN PostTypes pt ON pt.Id = p.PostTypeId
    WHERE pt.Name = 'Question'
    GROUP BY t.TagName
    HAVING COUNT(pt.PostId) > 5 -- Only tags with more than 5 questions
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.CreationDate > NOW() - INTERVAL '30 days') AS RecentVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        u.Reputation
    FROM Users u
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
    ORDER BY RecentVotes DESC, Reputation DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.CreationDate,
    pt.TagName,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.RecentVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM RankedPosts rp
JOIN PopularTags pt ON pt.PostCount > 5 -- Only join on tags with results
JOIN TopUsers tu ON tu.RecentVotes > 0 -- Ensure this user has recent activity
WHERE rp.Rank <= 5 -- Top 5 questions by view count
ORDER BY rp.ViewCount DESC, pt.PostCount DESC;
