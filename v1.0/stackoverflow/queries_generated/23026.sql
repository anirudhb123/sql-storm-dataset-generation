WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id
),
TagStats AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE
        t.IsModeratorOnly = 0
    GROUP BY
        t.Id
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty
    FROM
        Users u
    JOIN
        Votes v ON u.Id = v.UserId
    WHERE
        v.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY
        u.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ts.TagId,
    ts.TagName,
    au.UserId,
    au.DisplayName,
    au.TotalBounty,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        WHEN rp.CommentCount > 5 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostType
FROM
    RankedPosts rp
LEFT JOIN
    TagStats ts ON rp.PostId = ts.TagId
LEFT JOIN
    ActiveUsers au ON rp.PostId IN (
        SELECT
            p.Id
        FROM
            Posts p
        WHERE
            p.OwnerUserId = au.UserId
    )
WHERE
    rp.Score > 0
ORDER BY
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;

### Explanation:
1. **Common Table Expressions (CTEs)**: 
   - `RankedPosts` ranks posts of users by their score and counts comments.
   - `TagStats` aggregates the number of posts associated with each tag.
   - `ActiveUsers` sums bounty amounts for users who have voted within the last six months.

2. **Joins and Filtering**:
   - The main query joins these CTEs while applying filtering conditions, such as checking for posts created within the last year and having a score greater than zero.

3. **Case Expression**:
   - A `CASE` statement categorizes the posts as 'Top Post', 'Popular Post', or 'Regular Post' based on subreddit conditions.

4. **Window Function**: 
   - Uses `ROW_NUMBER()` to rank posts for each user based on their score.

5. **String and NULL Logic**: 
   - The query incorporates logic to handle nullable outer joins, ensuring that even posts without tags or associated users will be evaluated.

This complex SQL structure provides benchmarks for aspects like user activity, post popularity, and tag statistics, facilitating a broad analysis of the data within the given schema.
