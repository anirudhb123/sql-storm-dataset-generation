
WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT t.TagName) AS TagCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS IsQuestion,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS IsAnswer
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) as tag
         FROM Posts p CROSS JOIN 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 
          UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeClassSum
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
AggregatedResults AS (
    SELECT
        pt.PostId,
        pt.Title,
        pt.CreationDate,
        pt.TagCount,
        ur.DisplayName AS UserDisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.BadgeClassSum,
        CASE WHEN pt.IsQuestion > 0 THEN 'Question' ELSE 'Answer' END AS PostType
    FROM 
        PostTagCounts pt
    JOIN 
        UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pt.PostId)
)

SELECT 
    PostId,
    Title,
    CreationDate,
    TagCount,
    UserDisplayName,
    Reputation,
    PostCount,
    BadgeClassSum,
    PostType
FROM 
    AggregatedResults
WHERE 
    TagCount > 3
ORDER BY 
    CreationDate DESC, Reputation DESC
LIMIT 100;
