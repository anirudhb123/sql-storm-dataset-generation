WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
ScoreTrends AS (
    SELECT 
        OwnerUserId,
        AVG(Score) AS AvgPostScore,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN AcceptedAnswerId IS NOT NULL THEN Id END) AS AcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        s.AvgPostScore,
        s.TotalPosts,
        s.AcceptedAnswers,
        RANK() OVER (ORDER BY s.AvgPostScore DESC) AS Rank
    FROM 
        Users u
    JOIN 
        ScoreTrends s ON u.Id = s.OwnerUserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ph.Level, 0) AS MaxQuestionLevel,
    tu.AvgPostScore,
    tu.TotalPosts,
    tu.AcceptedAnswers
FROM 
    Users u
LEFT JOIN 
    PostHierarchy ph ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id IN (SELECT PostId FROM PostLinks pl WHERE pl.RelatedPostId = u.Id) LIMIT 1)
JOIN 
    TopUsers tu ON u.Id = tu.Id
WHERE 
    u.Location IS NOT NULL
    AND u.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY 
    tu.Rank, u.Reputation DESC;

### Explanation:
- **PostHierarchy CTE**: A recursive common table expression (CTE) that creates a hierarchy of posts, specifically starting with questions and traversing through answers to identify relationships based on parent-child post structures.
  
- **ScoreTrends CTE**: Calculates average scores and counts of total posts and accepted answers by each user. This is a summary that helps to understand user performance in contributing content.

- **TopUsers CTE**: Filters out users based on a reputation threshold and ranks them by their average post score.

- **Final SELECT Statement**: Combines results from `Users`, `PostHierarchy`, and `TopUsers`. It uses a LEFT JOIN to account for users with no posts while extracting maximum question levels they have contributed to, thereby allowing for a comprehensive benchmarking of user contributions. 

- **Conditions**: It filters users based on various criteria including a non-null location and users who created their accounts within the last year. 

- **Ordering**: The final result is ordered by the rank of users and by their reputation for easy analysis of top contributors.
