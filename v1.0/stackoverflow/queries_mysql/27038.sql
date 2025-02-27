
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM Posts p
    JOIN (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers, (SELECT @row := 0) r) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        GROUP_CONCAT(DISTINCT p.Title) AS ExampleTitles
    FROM PostTags pt
    JOIN Posts p ON pt.PostId = p.Id
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        ExampleTitles,
        RANK() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM TagStatistics
    WHERE QuestionCount > 5  
)
SELECT 
    t.Tag,
    t.QuestionCount,
    t.ExampleTitles,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM TopTags t
LEFT JOIN (
    SELECT 
        pt.Tag AS TagName,
        COUNT(*) AS BadgeCount
    FROM Badges b
    JOIN Users u ON b.UserId = u.Id
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN PostTags pt ON p.Id = pt.PostId
    GROUP BY pt.Tag
) b ON t.Tag = b.TagName
ORDER BY t.Rank;
