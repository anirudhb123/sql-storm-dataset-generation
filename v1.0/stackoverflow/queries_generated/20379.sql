WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- counting only upvotes
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate
    FROM 
        Users u
    WHERE 
        u.Reputation >= (SELECT AVG(Reputation) FROM Users)
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    COALESCE(rp.ViewCount, 0) AS TopPostViewCount,
    COALESCE(rp.Tags, 'No Tags') AS TopPostTags,
    CASE 
        WHEN rp.Rank IS NULL THEN 'N/A'
        ELSE rp.Rank::text
    END AS PostRank,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, rp.Title, rp.Score, rp.ViewCount, rp.Tags, rp.Rank
ORDER BY 
    TotalBadges DESC, TopPostScore DESC
LIMIT 5;

### Explanation:
1. **RankedPosts CTE**: This part computes a ranking of posts by each user based on the score within the last year. It also aggregates tags for those posts.
2. **TopUsers CTE**: This selects the top 10 users based on reputation, ensuring you only consider users with above-average reputations.
3. **Final SELECT**: Combines results from `TopUsers` and `RankedPosts`, displaying details about their top post and total badges, handling cases with no posts or ranks gracefully using `COALESCE`. The `GROUP BY` clause ensures aggregation by user while preserving relevant data.
4. **Null Logic Handling**: The use of `COALESCE` allows for a clear presentation even when certain data might be `NULL`.
5. **Ranking**: The ranking management checks for `NULL` and categorizes user posts accordingly.
6. **Final Ordering and Limiting**: Orders results by total badges first, then by post score to highlight the most contributing users effectively. 

This query is complex, uses multiple SQL features, and covers various corner cases related to user reputation, post scoring, and potential missing data points.
