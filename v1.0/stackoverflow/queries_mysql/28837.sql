
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS Frequency
    FROM Posts
    JOIN (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t, (SELECT @row := 0) r) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        Frequency,
        @rank := @rank + 1 AS Rank
    FROM TagCounts, (SELECT @rank := 0) r
    ORDER BY Frequency DESC
)
SELECT 
    t.TagName,
    t.Frequency AS UsageCount,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
FROM TopTags t
JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
JOIN Users u ON u.Id = p.OwnerUserId
WHERE t.Rank <= 10 
ORDER BY t.Frequency DESC, p.ViewCount DESC;
