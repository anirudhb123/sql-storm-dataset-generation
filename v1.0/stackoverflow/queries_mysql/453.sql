
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount,
        TotalViews,
        QuestionCount,
        AnswerCount,
        TotalScore,
        @rownum := @rownum + 1 AS ScoreRank
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalScore DESC
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason,
        @reason_rank := IF(@current_post = ph.PostId, @reason_rank + 1, 1) AS ReasonRank,
        @current_post := ph.PostId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes c ON c.Id = CAST(JSON_UNQUOTE(JSON_EXTRACT(ph.Comment, '$.closeReasonId')) AS UNSIGNED)
    CROSS JOIN (SELECT @reason_rank := 0, @current_post := NULL) r
    WHERE 
        ph.CreationDate IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    GROUP_CONCAT(DISTINCT cp.Title) AS ClosedPostsTitles,
    COUNT(DISTINCT cp.PostId) AS TotalClosedPosts,
    COALESCE(AVG(CASE WHEN cp.ReasonRank = 1 THEN 1 ELSE 0 END), 0) AS ReopenedPostsCount
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPosts cp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
WHERE 
    tu.ScoreRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.TotalViews, tu.QuestionCount, tu.AnswerCount, tu.TotalScore
ORDER BY 
    tu.TotalScore DESC;
