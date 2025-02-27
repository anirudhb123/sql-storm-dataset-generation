WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 -- We are only interested in questions
),
TagStatistics AS (
    SELECT
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM
        Posts
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
        u.Id
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
    TopTags tt ON rp.Tags ILIKE '%' || tt.TagName || '%'
JOIN
    UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE
    rp.PostRank <= 5 -- Only the top 5 questions per user
ORDER BY
    rp.CreationDate DESC;
