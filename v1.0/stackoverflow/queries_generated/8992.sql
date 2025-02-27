WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(tags, '><')) AS TagName,
        COUNT(*) AS TagUsage
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY TagName
    ORDER BY TagUsage DESC
    LIMIT 10
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        SUM(v.VoteTypeId = 10) AS Deletions
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.TotalScore,
    ua.TotalComments,
    ua.TotalBadges,
    ut.TotalPosts,
    ut.Upvotes,
    ut.Downvotes,
    ut.Deletions,
    pt.TagName,
    pt.TagUsage
FROM UserActivity ua
JOIN UserInteractions ut ON ua.UserId = ut.UserId
JOIN PopularTags pt ON pt.TagName = ANY (string_to_array(ua.TagNames, ','))
ORDER BY ua.TotalScore DESC, ut.Upvotes DESC
LIMIT 50;
