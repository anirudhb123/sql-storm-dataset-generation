WITH RecursiveTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <') AS t ON true
    GROUP BY 
        p.Id
),
HighestRatedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        COALESCE(MAX(c.Score), 0) AS HighestCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
    HAVING 
        p.Score > 10 AND COALESCE(MAX(c.Score), 0) > 0
),
UserReputationStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(u.Reputation) AS TotalReputation,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ut.UserId,
    ut.AvgReputation,
    ht.PostId,
    ht.Title,
    ht.ViewCount,
    ht.Score,
    rc.TagCount,
    rc.TagCount * ht.Score AS WeightedScore
FROM 
    UserReputationStats ut
INNER JOIN 
    HighestRatedPosts ht ON ut.PostsCount > 1
INNER JOIN 
    RecursiveTagCounts rc ON ht.PostId = rc.PostId
ORDER BY 
    WeightedScore DESC, 
    ht.ViewCount DESC
LIMIT 10;
