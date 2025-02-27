
WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        value AS Tag
    FROM
        Posts p
        CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS Tag
    WHERE
        p.PostTypeId = 1
),
PopularTags AS (
    SELECT
        Tag,
        COUNT(*) AS TagCount
    FROM
        PostTags
    GROUP BY
        Tag
    HAVING
        COUNT(*) > 10  
),
RecentUserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.LastActivityDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56') THEN 1 ELSE 0 END) AS RecentActivityCount,
        AVG(DATEDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AvgPostAge
    FROM
        Users u
        JOIN Posts p ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        RecentActivityCount,
        AvgPostAge,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM
        RecentUserActivity
    WHERE
        RecentActivityCount > 0
)
SELECT
    t.Tag,
    t.TagCount,
    tu.DisplayName,
    tu.QuestionCount,
    tu.RecentActivityCount,
    tu.AvgPostAge
FROM
    PopularTags t
JOIN
    TopUsers tu ON tu.QuestionCount > 5  
ORDER BY
    t.TagCount DESC, tu.QuestionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
