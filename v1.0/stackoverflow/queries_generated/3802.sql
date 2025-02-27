WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.PostTypeId = 1 -- Only questions
),
AggregateStats AS (
    SELECT 
        Owner,
        COUNT(PostId) AS TotalPosts,
        SUM(Score) AS TotalScore,
        AVG(Score) AS AverageScore,
        COUNT(DISTINCT PostId) AS UniquePosts,
        MAX(Score) AS MaxScore,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    GROUP BY 
        Owner
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalScore DESC) AS UserRank 
    FROM 
        AggregateStats
)
SELECT 
    tu.Owner,
    tu.TotalPosts,
    tu.TotalScore,
    tu.AverageScore,
    tu.MaxScore,
    tu.TotalComments
FROM 
    TopUsers tu
WHERE 
    tu.UserRank < 6 -- Top 5 users
ORDER BY 
    tu.TotalScore DESC;

-- This query benchmarks the performance of posts made by users in the last 30 days, 
-- aggregates their posts and provides stats for the top users based on their post attributes.
