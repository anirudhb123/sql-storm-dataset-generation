WITH TagStats AS (
    SELECT
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore,
        ARRAY_AGG(DISTINCT Posts.OwnerDisplayName) AS UniquePostOwners
    FROM
        Tags
    JOIN
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    WHERE
        Posts.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        Tags.TagName
),
ActiveUsers AS (
    SELECT
        Users.Id,
        Users.DisplayName,
        COUNT(Posts.Id) AS ContributionCount,
        SUM(Posts.Score) AS TotalScore
    FROM
        Users
    JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    WHERE
        Posts.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        Users.Id
    HAVING
        COUNT(Posts.Id) > 10
)
SELECT
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalScore,
    array_length(TS.UniquePostOwners, 1) AS UniqueOwnersCount,
    AU.DisplayName AS ActiveContributor,
    AU.ContributionCount AS ContributionsByContributor,
    AU.TotalScore AS ContributorScore
FROM
    TagStats TS
LEFT JOIN
    ActiveUsers AU ON TS.TagName = ANY(SELECT unnest(string_to_array((SELECT Tags FROM Posts WHERE OwnerUserId = AU.Id LIMIT 1), '><')))
ORDER BY
    TS.TotalScore DESC, TS.PostCount DESC;
