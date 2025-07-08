
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(SPLIT_PART(TRIM(BOTH '<>' FROM p.Tags), '>', seq)) AS Tag
    FROM Posts p
    JOIN (
        SELECT ROW_NUMBER() OVER() AS seq
        FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    ) seq ON seq.seq <= (LENGTH(TRIM(BOTH '<>' FROM p.Tags)) - LENGTH(REPLACE(TRIM(BOTH '<>' FROM p.Tags), '>', ''))) + 1
    WHERE p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        ARRAY_AGG(DISTINCT p.Title) AS ExampleTitles
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
