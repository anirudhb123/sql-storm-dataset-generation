WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStatistics
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount
FROM TopUsers tu
LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
WHERE tu.Rank <= 10
ORDER BY tu.Reputation DESC;

SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(v.DownVoteCount, 0) AS DownVoteCount
FROM Posts p
LEFT JOIN (
    SELECT
        PostId,
        COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
) c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Votes
    GROUP BY PostId
) v ON p.Id = v.PostId
WHERE p.CreationDate >= '2020-01-01'
AND (p.Score > 10 OR p.ViewCount > 1000)
ORDER BY p.ViewCount DESC
LIMIT 50;

SELECT
    p1.Tags AS PrimaryTags,
    p2.Tags AS SecondaryTags
FROM Posts p1
JOIN Posts p2 ON p1.Id <> p2.Id
WHERE ARRAY_LENGTH(string_to_array(SUBSTRING(p1.Tags, 2, LENGTH(p1.Tags)-2), '><'), 1) > 2
AND p1.CreationDate < p2.CreationDate
AND p1.Title ILIKE '%help%'
EXCEPT
SELECT DISTINCT
    p1.Tags
FROM Posts p1
WHERE p1.Title ILIKE '%spam%'
ORDER BY PrimaryTags;
