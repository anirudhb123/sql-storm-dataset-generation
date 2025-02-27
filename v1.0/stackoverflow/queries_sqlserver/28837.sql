
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            SUBSTRING(Tags, 2, LEN(Tags) - 2) AS Tags
        FROM Posts
        WHERE PostTypeId = 1 
    ) AS sub
    CROSS APPLY STRING_SPLIT(Tags, '><') 
    GROUP BY value
),
TopTags AS (
    SELECT 
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM TagCounts
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
JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
JOIN Users u ON u.Id = p.OwnerUserId
WHERE t.Rank <= 10 
ORDER BY t.Frequency DESC, p.ViewCount DESC;
