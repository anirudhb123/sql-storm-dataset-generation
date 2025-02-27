WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(DISTINCT post.Id) AS PostCount,
        SUM(CASE WHEN post.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN post.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags AS tag
    JOIN Posts AS post ON post.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY tag.TagName
),
UserReputation AS (
    SELECT
        user.Id AS UserId,
        user.Reputation,
        COUNT(DISTINCT post.Id) AS TotalPosts,
        COUNT(DISTINCT badge.Id) AS BadgeCount
    FROM Users AS user
    LEFT JOIN Posts AS post ON user.Id = post.OwnerUserId
    LEFT JOIN Badges AS badge ON user.Id = badge.UserId
    GROUP BY user.Id, user.Reputation
),
PostActivity AS (
    SELECT
        post.Id AS PostId,
        post.Title,
        COUNT(comment.Id) AS CommentCount,
        MAX(vote.CreationDate) AS LastVoteDate
    FROM Posts AS post
    LEFT JOIN Comments AS comment ON post.Id = comment.PostId
    LEFT JOIN Votes AS vote ON post.Id = vote.PostId
    GROUP BY post.Id, post.Title
)
SELECT
    tc.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    ur.UserId,
    ur.Reputation,
    ur.TotalPosts,
    ur.BadgeCount,
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.LastVoteDate,
    RANK() OVER (PARTITION BY tc.TagName ORDER BY tc.PostCount DESC) AS TagRank,
    RANK() OVER (PARTITION BY ur.UserId ORDER BY ur.Reputation DESC) AS ReputationRank
FROM TagCounts AS tc
JOIN UserReputation AS ur ON tc.PostCount > 0
JOIN PostActivity AS pa ON pa.CommentCount > 0
WHERE ur.Reputation > 50 AND tc.PostCount > 10
ORDER BY tc.TagName, ur.Reputation DESC, pa.CommentCount DESC;

