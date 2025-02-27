WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,  -- Counting Upvotes
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,       -- Number of comments
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,  -- Ranking posts per user by score
        CASE 
            WHEN p.ClosedDate IS NULL THEN 'Open' 
            ELSE 'Closed' 
        END AS Status
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Join for Upvotes
    LEFT JOIN 
        Comments c ON p.Id = c.PostId  -- Left join Comments to get count
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,       -- Counting distinct badges
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AvgBountyAmount  -- Average Bounty Amount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViews,
    rp.UpVotes,
    rp.CommentCount,
    us.DisplayName AS Author,
    us.Reputation AS AuthorReputation,
    us.BadgeCount,
    us.AvgBountyAmount,
    rp.Status,
    CASE 
        WHEN rp.Status = 'Closed' AND rp.Rank <= 5 
            THEN 'Top Closed Post'
        ELSE 'Other'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    (rp.Score > 10 AND rp.Status = 'Open') 
    OR (rp.Status = 'Closed' AND rp.CommentCount > 3)
ORDER BY 
    rp.Score DESC nulls last,  -- Order by Post Score, nulls last
    us.Reputation DESC;  -- Then order by Author Reputation

-- NOTE: This SQL query is designed to benchmark performance with multiple concepts:
-- CTEs, window functions, outer joins, aggregation, and complex filtering.
-- Corner cases like counting nulls effectively with the FILTER clause and ordering 
-- while handling NULLs distinctively demonstrate some advanced SQL functionalities.
