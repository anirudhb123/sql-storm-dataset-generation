WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE  -- Assuming Tags are in <tag1><tag2> format
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.VoteCount,
        cp.FirstClosedDate,
        COALESCE(STRING_AGG(b.Name, ', '), 'No Badges') AS UserBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId) -- Owner's Badges
    WHERE 
        rp.Rank <= 5 AND 
        (rp.Score > 10 OR cp.FirstClosedDate IS NULL) -- Top 5 Posts by Score or Posts not Closed
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, cp.FirstClosedDate
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.VoteCount,
    pp.FirstClosedDate,
    pp.UserBadges,
    CASE 
        WHEN pp.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PopularPosts pp
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;

This complex SQL query does the following:

1. Defines a `RankedPosts` common table expression (CTE) that ranks posts by score and creation date, aggregating their tags and counting votes.
2. Defines a `ClosedPosts` CTE that captures the first date a post was closed.
3. Defines a `PopularPosts` CTE that aggregates data about popular posts, including their associated user badges.
4. The final select statement retrieves relevant columns from `PopularPosts`, adding a calculated field to determine if the post is closed or open.
5. The `ORDER BY` clause ensures the results are sorted by score and then by view count, ensuring visibility of high-engagement posts.

Additional complexities involve the use of outer joins, correlated subqueries, window functions, and conditional logic for post status.
