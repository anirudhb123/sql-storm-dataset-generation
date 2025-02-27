WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS AnsweredQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes, 
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), 
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), 
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        u.DisplayName AS LastEditor
    FROM 
        Posts p
    JOIN 
        Users u ON p.LastEditorUserId = u.Id
    WHERE 
        p.LastActivityDate IS NOT NULL
)

SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.QuestionCount,
    ue.AnsweredQuestions,
    ue.AnswersGiven,
    ue.TotalBounty,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    tq.Title AS TopQuestionTitle,
    tq.Score AS TopQuestionScore,
    ra.LastActivityDate,
    ra.LastEditor
FROM 
    UserEngagement ue
LEFT JOIN 
    TopQuestions tq ON ue.QuestionCount > 0
LEFT JOIN 
    RecentActivity ra ON ra.PostId = tq.PostId
ORDER BY 
    ue.TotalBounty DESC, ue.TotalUpvotes DESC
LIMIT 10;
