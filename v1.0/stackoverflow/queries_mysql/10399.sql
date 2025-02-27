
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS CommentScore,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COALESCE(ph.Comment, 'No Comment') AS LastEditComment,
        p.OwnerUserId,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS LastPostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId,
        (SELECT @row_number := 0, @current_user := NULL) AS init
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalViews,
    us.TotalScore,
    us.CommentScore,
    us.AvgReputation,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.Tags,
    pm.LastEditComment
FROM 
    UserStats us
LEFT JOIN 
    PostMetrics pm ON us.UserId = pm.OwnerUserId
WHERE 
    us.QuestionCount > 0
ORDER BY 
    us.TotalScore DESC, us.QuestionCount DESC;
