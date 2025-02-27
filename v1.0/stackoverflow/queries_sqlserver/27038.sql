
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS TagValue
    WHERE p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        pt.Tag,
        COUNT(*) AS QuestionCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS ExampleTitles
    FROM PostTags pt
    JOIN Posts p ON pt.PostId = p.Id
    GROUP BY pt.Tag
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
