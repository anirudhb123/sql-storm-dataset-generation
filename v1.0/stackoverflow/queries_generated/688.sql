WITH UserPostScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        TotalScore,
        TotalViews,
        ScoreRank
    FROM UserPostScores
    WHERE ScoreRank <= 10
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score AS PostScore,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON c.PostId = p.Id
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(p.Tags, '>')) AS TagName
    ) t ON TRUE
    GROUP BY p.Id, p.Title, p.Score
),
Leaderboard AS (
    SELECT 
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalScore,
        tu.TotalViews,
        pwc.PostId,
        pwc.Title,
        pwc.PostScore,
        pwc.CommentCount,
        pwc.Tags
    FROM TopUsers tu
    JOIN PostWithComments pwc ON pwc.PostScore > 5  -- Only consider posts with score > 5
)
SELECT 
    l.DisplayName,
    l.TotalPosts,
    l.TotalScore,
    l.TotalViews,
    l.PostId,
    l.Title,
    l.PostScore,
    l.CommentCount,
    l.Tags,
    CASE 
        WHEN l.TotalScore > 50 THEN 'Veteran'
        WHEN l.TotalScore BETWEEN 20 AND 50 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel
FROM Leaderboard l
ORDER BY l.TotalScore DESC, l.DisplayName;
