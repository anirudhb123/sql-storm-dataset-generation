
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 
            @rownum := @rownum + 1 AS n 
         FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n,
            (SELECT @rownum := 0) r) n
    WHERE 
        p.PostTypeId = 1 AND
        n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredQuestions,
        COUNT(b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        um.DisplayName,
        um.QuestionCount,
        um.PositiveScoredQuestions,
        um.NegativeScoredQuestions,
        um.BadgesCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserMetrics um,
        (SELECT @rank := 0) r
    ORDER BY 
        um.QuestionCount DESC, um.PositiveScoredQuestions DESC
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.QuestionCount,
    tu.PositiveScoredQuestions,
    tu.NegativeScoredQuestions,
    tu.BadgesCount,
    tg.Tag,
    tg.UsageCount
FROM 
    TopUsers tu
JOIN 
    TagUsage tg ON tg.UsageCount = (SELECT MAX(UsageCount) FROM TagUsage)
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, tg.Tag;
