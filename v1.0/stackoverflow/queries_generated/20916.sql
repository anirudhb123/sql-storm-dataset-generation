WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    up.DisplayName AS "User",
    fp.Title AS "Post Title",
    fp.CreationDate AS "Posted On",
    fp.Score AS "Score",
    fp.ViewCount AS "Views",
    (
        SELECT 
            STRING_AGG(DISTINCT gt.TagName, ', ') 
        FROM 
            Tags gt 
        JOIN 
            Posts pt ON gt.Id = ANY(string_to_array(pt.Tags, ',')::int[]) 
        WHERE 
            pt.Id = fp.PostId
    ) AS "Tags",
    (
        SELECT 
            COUNT(*) 
        FROM 
            Votes v 
        WHERE 
            v.PostId = fp.PostId 
            AND v.VoteTypeId = 2 
    ) AS "UpVotes",
    NULLIF(
        (
            SELECT 
                AVG(v.BountyAmount) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = fp.PostId 
                AND v.VoteTypeId = 8
        ), 
        0
    ) AS "Average Bounty"
FROM 
    FilteredPosts fp
JOIN 
    Users up ON up.Id = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = fp.PostId
    )
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 10;

-- Additional Filtering with Outer Join to capture Users with no Activity
LEFT JOIN (
    SELECT 
        u.DisplayName AS "User", 
        COUNT(up.Id) AS "Post Count"
    FROM 
        Users u
    LEFT JOIN 
        Posts up ON u.Id = up.OwnerUserId
    GROUP BY 
        u.Id
) AS userActivity ON userActivity.User = up.DisplayName
WHERE 
    userActivity."Post Count" IS NULL
AND 
    up.Reputation > 1000; 
This SQL query incorporates various advanced SQL constructs:

1. Common Table Expressions (CTEs) for organizing the query into logical sections (`RankedPosts` and `FilteredPosts`).
2. Window functions (ROW_NUMBER, COUNT) to rank posts and count related comments.
3. Subqueries to aggregate tags and upvotes dynamically.
4. Conditional aggregation with `NULLIF` to calculate average bounty values while handling division by zero.
5. Efficient filtering and outer join to demonstrate corner case capture for users without posts but having significant reputation.
