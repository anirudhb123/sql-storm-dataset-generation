WITH UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalViews,
        ps.AvgScore
    FROM 
        UserBadgeCount ub
    JOIN 
        PostStatistics ps ON ub.UserId = ps.OwnerUserId
    ORDER BY 
        ub.BadgeCount DESC, ps.PostCount DESC, ps.TotalViews DESC
    LIMIT 10
),
CommentsStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.BadgeCount,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalViews,
    tu.AvgScore,
    COALESCE(cs.CommentCount, 0) AS MostCommentsCount,
    COALESCE(cs.LastCommentDate, 'No comments') AS LastCommentDate
FROM 
    TopUsers tu
LEFT JOIN 
    CommentsStats cs ON cs.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId
    )
ORDER BY 
    tu.BadgeCount DESC, 
    tu.PostCount DESC;
