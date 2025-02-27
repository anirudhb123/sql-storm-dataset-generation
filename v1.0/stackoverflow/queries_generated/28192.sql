WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.PostType,
        rp.TagCount
    FROM
        RankedPosts rp
    WHERE
        rp.UserPostRank <= 5 -- Only the top 5 posts for each user
),

TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(f.PostId) AS PostCount,
        SUM(f.ViewCount) AS TotalViews,
        SUM(f.Score) AS TotalScore
    FROM
        Users u
    JOIN
        FilteredPosts f ON u.Id = f.PostId
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        PostCount DESC, TotalViews DESC
    LIMIT 10
)

SELECT
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CreationDate
FROM
    TopUsers tu
JOIN
    FilteredPosts fp ON tu.UserId = fp.PostId
ORDER BY
    tu.TotalScore DESC, fp.ViewCount DESC;

This SQL query benchmarks string processing by analyzing posts from users, specifically those created in the last year. It evaluates the top posts based on view count and score, ensuring each user is only represented by their top 5 posts. The final output comprises a list of the top 10 users ranked by the number of posts and their respective interactions, joined back with filtered posts to provide detailed insights.
