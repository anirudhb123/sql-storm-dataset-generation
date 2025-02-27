WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        p2.CreationDate,
        p2.Score,
        p2.ViewCount,
        p2.OwnerUserId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePosts rp ON p2.ParentId = rp.Id
    WHERE 
        p2.PostTypeId = 2  -- Answers
),

PostStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(DISTINCT rp.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN rp.AcceptedAnswerId IS NOT NULL THEN rp.Id END) AS AnsweredQuestionCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RecursivePosts rp
    GROUP BY 
        rp.OwnerUserId
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ps.QuestionCount,
        ps.AnsweredQuestionCount,
        ps.TotalScore,
        ps.TotalViews,
        ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 1000  -- Consider users with reputation over 1000
)

SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnsweredQuestionCount,
    tu.TotalScore,
    tu.TotalViews
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10  -- Get top 10 users
ORDER BY 
    tu.TotalScore DESC;

-- Execute to retrieve the top 10 users by score who have asked questions and received answered questions
