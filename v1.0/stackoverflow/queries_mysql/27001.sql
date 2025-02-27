
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM
        Posts
    JOIN
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE
        PostTypeId = 1
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName
    FROM
        TagStatistics
    ORDER BY
        TagCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM
        Users u
    JOIN
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
)

SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    COALESCE(tt.TagName, 'No Tags') AS PopularTag,
    ua.DisplayName AS ActiveUser,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.AvgReputation
FROM
    RankedPosts rp
LEFT JOIN
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%')
JOIN
    UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE
    rp.PostRank <= 5 
ORDER BY
    rp.CreationDate DESC;
