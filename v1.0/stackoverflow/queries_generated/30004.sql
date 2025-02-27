WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPosts
    FROM
        Posts p
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart, BountyClose
    WHERE
        u.LastAccessDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY
        u.Id, u.DisplayName, u.Reputation, u.Views
),
TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY
        t.TagName
)
SELECT
    u.DisplayName AS ActiveUser,
    u.Reputation,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score AS PostScore,
    r.ViewCount,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.AvgViews AS AverageTagViews,
    u.TotalBounties
FROM
    ActiveUsers u
JOIN
    RankedPosts r ON u.PostCount > 0
LEFT JOIN
    TagStatistics ts ON ts.PostCount > 10  -- Only tags with more than 10 posts
WHERE
    r.RankByScore <= 5  -- Top 5 posts per post type
ORDER BY
    u.Reputation DESC, r.Score DESC, ts.TagPostCount DESC;
This query includes several advanced SQL concepts:

1. **Common Table Expressions (CTEs)** for structured and reusable subqueries, including:
   - `RankedPosts` to rank posts based on score and create a subset of recent posts.
   - `ActiveUsers` to aggregate user activity and revenue from bounties.
   - `TagStatistics` to summarize tag-related statistics.

2. **Window functions**: `RANK()` and `ROW_NUMBER()` to calculate rankings and recency.

3. **Joins and Aggregations** to consolidate user, post, and tag data.

4. **Complicated predicates** to filter results based on multiple criteria, including subqueries and pattern matching.

5. **String expressions** in the tag join condition for searching post tags. 

6. **NULL logic** with `COALESCE()` for handling potential nulls in the aggregate calculations.

7. The **ORDER BY** clause to sort results according to user reputation and post score. 

This query aims to provide insights into active users and their engagements with high-ranking posts and popular tags on a platform like Stack Overflow.
