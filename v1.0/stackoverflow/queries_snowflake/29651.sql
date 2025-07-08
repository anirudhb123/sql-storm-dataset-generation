
WITH TagCounts AS (
    SELECT
        TagName,
        COUNT(*) AS PostCount
    FROM (
        SELECT
            unnest(split(substr(Tags, 2, len(Tags) - 2), '><')) AS TagName
        FROM
            Posts
        WHERE
            PostTypeId = 1 
    )
    GROUP BY
        TagName
), PopularTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagCounts
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
        LISTAGG(b.Name, ', ') AS BadgeNames
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
        PopularTags pt ON pt.TagName = ANY(split(substr(p.Tags, 2, len(p.Tags) - 2), '><'))
    WHERE
        p.PostTypeId = 1 
)
SELECT
    c.OwnerDisplayName,
    c.TagName,
    COUNT(c.Title) AS NumberOfQuestions,
    AVG(c.ViewCount) AS AvgViewCount,
    AVG(c.Score) AS AvgScore,
    LISTAGG(DISTINCT c.BadgeNames, ', ') AS AssociatedBadges
FROM
    CombinedData c
GROUP BY
    c.OwnerDisplayName,
    c.TagName
ORDER BY
    NumberOfQuestions DESC, 
    AvgScore DESC
LIMIT 10;
