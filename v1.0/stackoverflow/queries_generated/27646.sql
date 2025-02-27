WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.Tags, 
           p.CreationDate, 
           u.DisplayName AS OwnerDisplayName, 
           ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Only questions
), 
TagCounts AS (
    SELECT unnest(string_to_array(p.Tags, '><')) AS TagName, 
           COUNT(*) AS PostCount
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY unnest(string_to_array(p.Tags, '><'))
), 
PopularTags AS (
    SELECT TagName, 
           PostCount, 
           RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
    WHERE PostCount > 5 -- Only tags with more than 5 associated posts
), 
UserActivities AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(*) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT rp.Title, 
       rp.CreationDate, 
       rp.OwnerDisplayName, 
       pt.TagName, 
       pa.PostCount, 
       ua.DisplayName AS ActiveUser, 
       ua.TotalPosts, 
       ua.AnswerCount, 
       ua.QuestionCount
FROM RankedPosts rp
JOIN PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
JOIN UserActivities ua ON rp.OwnerUserId = ua.UserId
WHERE rp.Rank <= 10 -- Get top 10 recent questions
ORDER BY rp.CreationDate DESC, pt.PostCount DESC;
