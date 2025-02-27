WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),

PopularTags AS (
    SELECT 
        unnest(string_to_array(STRING_AGG(DISTINCT p.Tags, ', '), ', ')) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY TagName
),

TopThreeTags AS (
    SELECT 
        TagName,
        PostCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM PopularTags
    WHERE PostCount > 5 -- Only tags with more than 5 posts
)

SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.BadgeCount,
    ua.UpVotes,
    ua.DownVotes,
    tt.TagName AS MostPopularTag
FROM UserActivity ua
LEFT JOIN TopThreeTags tt ON tt.TagRank = 1 -- Join with the most popular tag
WHERE ua.Rank <= 10 -- Top 10 users by uploaded questions
ORDER BY ua.QuestionCount DESC;
