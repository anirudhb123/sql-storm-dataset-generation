
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL 1 YEAR
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        MIN(rp.CreationDate) AS FirstPostDate,
        MAX(rp.CreationDate) AS LatestPostDate
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT rp.PostId) > 5 
),
UserBadgeStats AS (
    SELECT 
        ub.UserId,
        COUNT(ub.Id) AS BadgeCount,
        MAX(ub.Class) AS HighestBadgeClass
    FROM 
        Badges ub
    JOIN 
        TopUsers tu ON ub.UserId = tu.UserId
    GROUP BY 
        ub.UserId
),
PostTagStats AS (
    SELECT 
        rp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', numbers.n), '>', -1) AS TagName
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '>', '')) >= numbers.n - 1
),
TagUsageCount AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM 
        PostTagStats
    GROUP BY 
        TagName
    ORDER BY 
        UsageCount DESC
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.TotalScore,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS HighestBadge,
    (SELECT GROUP_CONCAT(TagName ORDER BY UsageCount DESC SEPARATOR ', ') FROM TagUsageCount WHERE UsageCount > 5 LIMIT 5) AS PopularTags
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadgeStats ub ON tu.UserId = ub.UserId
ORDER BY 
    tu.QuestionCount DESC,
    tu.TotalScore DESC;
