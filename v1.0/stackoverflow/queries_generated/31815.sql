WITH RecursiveTopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostsRanked AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        p.Title, 
        p.CreationDate, 
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.PostId) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        PostsRanked p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.PostId = c.PostId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalComments
FROM 
    RecursiveTopUsers t
JOIN 
    UserPostStats ups ON t.UserId = ups.UserId
WHERE 
    ups.TotalPosts > 5
ORDER BY 
    t.Rank, ups.TotalScore DESC
LIMIT 10;
This SQL query does the following:
1. Defines recursive CTEs to create a ranking of top users with a reputation greater than 1000.
2. Ranks posts by creation date and counts comments per post within the last year.
3. Joins users with their respective posts while aggregating statistics such as total posts, total score, and total comments.
4. Filters the results for users with more than 5 posts and orders the output by rank and score, limiting to the top 10 results.
