
WITH ComputedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', num.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
    (
        SELECT 
            a.N + b.N * 10 AS n
        FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
             SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
             SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
    ) num ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= num.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        COUNT(DISTINCT pt.OwnerUserId) AS UserCount,
        AVG(pt.Score) AS AverageScore
    FROM 
        ComputedTags ct
    JOIN 
        Posts pt ON ct.PostId = pt.Id
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        UserCount,
        AverageScore,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    ORDER BY 
        PostCount DESC, AverageScore DESC
)
SELECT 
    t.Tag,
    t.PostCount,
    t.UserCount,
    t.AverageScore,
    COALESCE(b.BadgeName, 'No Badge') AS BadgeName,
    COUNT(DISTINCT b.UserId) AS BadgeWinners
FROM 
    TopTags t
LEFT JOIN 
    (
        SELECT 
            b.Name AS BadgeName,
            b.UserId
        FROM 
            Badges b
        WHERE 
            b.Class = 1 OR b.Class = 2  
    ) b ON t.UserCount >= 10 
WHERE 
    t.Rank <= 10 
GROUP BY 
    t.Tag, t.PostCount, t.UserCount, t.AverageScore, b.BadgeName
ORDER BY 
    t.PostCount DESC, t.AverageScore DESC;
