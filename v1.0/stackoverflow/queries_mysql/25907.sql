
WITH TagFrequency AS (
    SELECT 
        tag.value AS Tag,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS value
        FROM Posts
        JOIN (
            SELECT a.N + b.N * 10 AS n 
            FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
            CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) n ON n.n <= 1 + (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', ''))) 
        WHERE PostTypeId = 1  
    ) AS tag
    GROUP BY tag.value
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(DISTINCT p.Id) AS AnswerCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 2  
    GROUP BY u.Id, u.DisplayName
),
TagPostCount AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
HighlyActiveUsers AS (
    SELECT 
        pu.UserId, 
        pu.DisplayName, 
        pu.TotalViews, 
        pu.UpVotes,
        @row_number := @row_number + 1 AS Rank
    FROM PopularUsers pu, (SELECT @row_number := 0) r
    WHERE pu.AnswerCount > 10
    ORDER BY pu.TotalViews DESC
)
SELECT 
    tf.Tag,
    tf.Frequency,
    tp.PostCount,
    hau.DisplayName AS ActiveUser,
    hau.TotalViews,
    hau.UpVotes
FROM TagFrequency tf
JOIN TagPostCount tp ON tf.Tag = tp.TagName
LEFT JOIN HighlyActiveUsers hau ON tp.PostCount > 5  
ORDER BY tf.Frequency DESC, tp.PostCount DESC;
