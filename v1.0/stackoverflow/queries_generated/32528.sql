WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(CAST(ROUND(AVG(v.VoteTypeId) OVER (PARTITION BY p.Id), 2) AS DECIMAL(10, 2)), 0) AS AverageVote
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCount,
        TotalCommentScore,
        LastPostDate,
        RANK() OVER (ORDER BY PostsCount DESC, TotalCommentScore DESC) AS UserRank
    FROM 
        RecentUserActivity
)
SELECT 
    pu.PostId,
    pu.Title,
    pu.CreationDate,
    pu.Score,
    pu.ViewCount,
    pu.AverageVote,
    tu.DisplayName AS TopUserDisplayName,
    tu.PostsCount AS TopUserPostsCount,
    tu.TotalCommentScore AS TopUserCommentScore,
    pu.Rank AS PostRank
FROM 
    RankedPosts pu
LEFT JOIN 
    TopUsers tu ON pu.PostId = (
        SELECT 
            p.Id 
        FROM 
            Posts p
        WHERE 
            p.OwnerUserId = tu.UserId
        ORDER BY 
            p.ViewCount DESC
        LIMIT 1
    )
WHERE 
    pu.Rank <= 5
ORDER BY 
    pu.PostTypeId, pu.Score DESC;

This SQL query performs the following:

1. **CTE `RankedPosts`:** It ranks posts by their creation date while calculating the average vote type id (as a measure of engagement).
2. **CTE `RecentUserActivity`:** It aggregates user activity, counting posts and summing comment scores for users, capturing their last post date.
3. **CTE `TopUsers`:** It ranks users based on their post count and comment scores.
4. The main query combines information from the `RankedPosts` and `TopUsers`, joining them on the highest viewed post by each top user and selecting the top 5 posts for each post type. The results are then ordered by the post type and score. 

This complex query structure enables performance benchmarking across posts and user activities efficiently while utilizing multiple SQL constructs.
