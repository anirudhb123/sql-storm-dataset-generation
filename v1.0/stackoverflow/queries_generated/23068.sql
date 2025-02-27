WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id
),
BountiedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        bp.BountyAmount,
        CASE WHEN bp.BountyAmount IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasBounty
    FROM
        Posts p
    LEFT JOIN
        Votes bp ON p.Id = bp.PostId AND bp.VoteTypeId = 8
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT bh.PostId) AS PostsEdited,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 9
    LEFT JOIN
        PostHistory bh ON u.Id = bh.UserId
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    GROUP BY
        u.Id
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT ph.Id) AS CloseReasons
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY
        p.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    bp.HasBounty,
    ua.DisplayName AS UserCreator,
    ua.TotalBounties,
    ua.PostsEdited,
    ua.CommentsMade,
    cp.CloseReasons
FROM
    RankedPosts rp
LEFT JOIN
    BountiedPosts bp ON rp.PostId = bp.PostId
LEFT JOIN
    Users ua ON rp.Score > 5 -- Arbitrary filter to demonstrate outer joins with conditions
LEFT JOIN
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE
    COALESCE(rp.Tags, '') LIKE '%SQL%'
ORDER BY
    rp.Rank, rp.Score DESC
LIMIT 1000;

This query dynamically calculates and ranks posts based on a range of criteria, showcasing the use of common table expressions (CTEs) for modular approach, outer joins, correlated subqueries, aggregations, window functions, and various joins while addressing corner cases and semantic quirks such as handling NULLs and string expressions. It leverages the diverse schema provided for complex interactions between posts, votes, users, and their activities.
