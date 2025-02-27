WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        ARRAY_AGG(t.TagName) AS TagsArray
    FROM 
        Posts p
        LEFT JOIN LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON true
        LEFT JOIN Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
PostStats AS (
    SELECT 
        post.OwnerUserId,
        COUNT(post.Id) AS TotalPosts,
        SUM(post.Score) AS TotalScore,
        AVG(post.ViewCount) AS AvgViewCount,
        MAX(post.ViewCount) AS MaxViewCount,
        MIN(post.ViewCount) AS MinViewCount,
        MAX(post.CreationDate) AS LatestPost
    FROM 
        Posts post
    GROUP BY 
        post.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ps.TotalPosts, 
        ps.TotalScore, 
        ps.AvgViewCount,
        RANK() OVER (ORDER BY ps.TotalScore DESC) AS ScoreRank
    FROM 
        Users u
        JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.AvgViewCount,
    COALESCE(rp.TagsArray, '{}') AS AssociatedTags,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.Id AND p.CreationDate > NOW() - INTERVAL '1 year') AS RecentPostsLastYear
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.Id = rp.OwnerUserId 
WHERE 
    tu.TotalPosts >= 5
ORDER BY 
    tu.TotalScore DESC, 
    tu.DisplayName
LIMIT 10;

This query performs the following operations:

1. **RankedPosts CTE**: Gets posts, ranks them per user based on score, and collects tags associated with each post.
   
2. **PostStats CTE**: Aggregates information about the total number of posts, total score, average view count, maximum view count, minimum view count, and the timestamp of the latest post for each user.

3. **TopUsers CTE**: Joins `Users` with `PostStats` to rank users based on their total score.

4. The main query selects user stats, collects associated tags from `RankedPosts`, and counts recent posts for each user, with necessary conditions applied for filtering and ordering, while handling potential NULL values for tags. 

This query has complex logic dealing with window functions, subqueries, and joins while involving aggregate functions and an outer join.
