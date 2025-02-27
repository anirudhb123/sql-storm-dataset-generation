
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON 
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
TagFrequencies AS (
    SELECT 
        Tag,
        COUNT(*) AS Frequency
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    tf.Tag,
    tf.Frequency,
    au.UserId,
    au.PostCount,
    (SELECT COUNT(DISTINCT p.Id) 
     FROM Posts p 
     WHERE p.Tags LIKE CONCAT('%', tf.Tag, '%')) AS TotalPostsWithTag
FROM 
    TagFrequencies tf
CROSS JOIN 
    ActiveUsers au
WHERE 
    tf.Frequency > 5
ORDER BY 
    tf.Frequency DESC, au.PostCount DESC;
