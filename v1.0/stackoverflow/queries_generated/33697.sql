WITH RECURSIVE TaggedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, t.TagName
    FROM Posts p
    JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE p.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, t.TagName
    FROM Posts p
    JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    INNER JOIN TaggedPosts tp ON p.ParentId = tp.Id  -- Recursive join for tags from parent posts
),
BadgeCounts AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation,
           CASE 
               WHEN b.BadgeCount > 5 THEN 'Highly Recognized'
               WHEN b.BadgeCount BETWEEN 1 AND 5 THEN 'Moderately Recognized'
               ELSE 'Less Recognized'
           END AS RecognitionLevel
    FROM Users u
    LEFT JOIN BadgeCounts b ON u.Id = b.UserId
),
PostActivity AS (
    SELECT p.Id AS PostId, p.Title, p.ViewCount, p.AnswerCount, u.DisplayName AS OwnerName,
           DATEDIFF(CURRENT_DATE, p.CreationDate) AS DaysOld
    FROM Posts p
    JOIN Users u on p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Only questions
),
AggregateData AS (
    SELECT tp.TagName, COUNT(tp.Id) AS NumberOfQuestions, AVG(pa.ViewCount) AS AvgViews,
           SUM(pa.AnswerCount) AS TotalAnswers, AVG(pa.DaysOld) AS AvgPostAge
    FROM TaggedPosts tp
    JOIN PostActivity pa ON tp.Id = pa.PostId
    GROUP BY tp.TagName
),
TopTags AS (
    SELECT TagName, NumberOfQuestions, AvgViews, TotalAnswers, AvgPostAge,
           RANK() OVER (ORDER BY NumberOfQuestions DESC) AS Rank
    FROM AggregateData
)
SELECT tt.TagName, tt.NumberOfQuestions, tt.AvgViews, tt.TotalAnswers, tt.AvgPostAge,
       ur.DisplayName, ur.Reputation, ur.RecognitionLevel
FROM TopTags tt
LEFT JOIN Users u on tt.TagName = u.EmailHash  -- Assuming users have unique tags tied to them
LEFT JOIN UserReputation ur on u.Id = ur.UserId
WHERE tt.Rank <= 10  -- Top 10 tags
ORDER BY tt.NumberOfQuestions DESC, tt.AvgViews DESC;
