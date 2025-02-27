WITH UserTags AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT t.Id) AS TagCount,
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tagName(t) ON TRUE
    JOIN Tags t ON t.TagName = trim(t.tagName)
    GROUP BY u.Id, u.DisplayName
),
TagActivity AS (
    SELECT t.Id AS TagId,
           t.TagName,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%<' || t.TagName || '>%' -- To find posts with the tag
    GROUP BY t.Id, t.TagName
),
UserReputation AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           ut.TagsUsed,
           ut.TagCount
    FROM Users u
    JOIN UserTags ut ON u.Id = ut.UserId
)
SELECT u.UserId, 
       u.DisplayName, 
       u.Reputation, 
       ut.TagCount, 
       ut.TagsUsed, 
       COALESCE(SUM(ta.PostCount), 0) AS TotalPosts,
       COALESCE(MAX(ta.PostCount), 0) AS MaxPostsByTag,
       COALESCE(SUM(ta.QuestionCount), 0) AS TotalQuestions,
       COALESCE(SUM(ta.AnswerCount), 0) AS TotalAnswers
FROM UserReputation u
LEFT JOIN TagActivity ta ON u.TagsUsed LIKE CONCAT('%', ta.TagName, '%')
GROUP BY u.UserId, u.DisplayName, u.Reputation, ut.TagCount, ut.TagsUsed
ORDER BY u.Reputation DESC, TotalPosts DESC
LIMIT 10;

