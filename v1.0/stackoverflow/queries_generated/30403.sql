WITH RECURSIVE UserTagCount AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY u.Id
),
TagDetails AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY t.Id, t.TagName
),
RecentPostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.LastActivityDate > NOW() - INTERVAL '30 days' -- Recent activity
    GROUP BY p.Id, p.Title
),
PopularUsers AS (
    SELECT
        UserId,
        Reputation,
        Rank() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
    WHERE Reputation > 1000
)
SELECT 
    u.DisplayName AS UserName,
    utc.QuestionCount,
    utc.AnswerCount,
    COALESCE(td.PostCount, 0) AS TotalPostByTags,
    COALESCE(td.AvgBounty, 0) AS AvgBountyForTags,
    rpa.Title AS RecentPostTitle,
    rpa.CommentCount AS RecentCommentCount,
    rpa.LastCommentDate,
    pu.UserRank
FROM UserTagCount utc
JOIN Users u ON utc.UserId = u.Id
LEFT JOIN TagDetails td ON td.TagId IN (SELECT UNNEST(string_to_array((SELECT Tags FROM Posts WHERE OwnerUserId = u.Id LIMIT 1), ',')))::int[] -- Using a subquery to fetch tags used by first post of user
LEFT JOIN RecentPostActivity rpa ON u.Id = rpa.PostId
JOIN PopularUsers pu ON u.Id = pu.UserId
WHERE utc.QuestionCount > 10 -- Only users with more than 10 questions
ORDER BY u.Reputation DESC, TotalPostByTags DESC
LIMIT 100;

