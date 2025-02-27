
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
), PopularTags AS (
    SELECT
        TagName,
        PostCount,
        @row_number := @row_number + 1 AS Rank
    FROM
        TagCounts, (SELECT @row_number := 0) AS rn
    WHERE
        PostCount > 10 
),
MostActiveUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastQuestionDate
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        u.Id, u.DisplayName
    HAVING
        COUNT(p.Id) > 5 
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
    FROM
        Badges b
    GROUP BY
        b.UserId
),
CombinedData AS (
    SELECT
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        COALESCE(pb.BadgeNames, 'No Badges') AS BadgeNames,
        pt.TagName
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        UserBadges pb ON u.Id = pb.UserId
    JOIN
        PopularTags pt ON FIND_IN_SET(pt.TagName, SUBSTRING(REPLACE(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<', -1), '>', 1), '>', ''), 2)) > 0
    WHERE
        p.PostTypeId = 1 
)
SELECT
    c.OwnerDisplayName,
    c.TagName,
    COUNT(c.Title) AS NumberOfQuestions,
    AVG(c.ViewCount) AS AvgViewCount,
    AVG(c.Score) AS AvgScore,
    GROUP_CONCAT(DISTINCT c.BadgeNames SEPARATOR ', ') AS AssociatedBadges
FROM
    CombinedData c
GROUP BY
    c.OwnerDisplayName,
    c.TagName
ORDER BY
    NumberOfQuestions DESC, 
    AvgScore DESC
LIMIT 10;
