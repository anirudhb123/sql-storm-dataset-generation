WITH UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        ue.DisplayName,
        ue.TotalPosts,
        ue.QuestionCount,
        ue.AnswerCount,
        ue.AcceptedAnswers,
        ue.CommentCount,
        ue.TotalBounties,
        RANK() OVER (ORDER BY ue.TotalPosts DESC) AS Rank
    FROM 
        UserEngagement ue
),
TagStatistics AS (
    SELECT
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
TagEngagement AS (
    SELECT 
        ts.TagName,
        COUNT(*) AS PostCount,
        SUM(ue.QuestionCount) AS QuestionCount,
        SUM(ue.AcceptedAnswers) AS AcceptedQuestionCount
    FROM 
        TagStatistics ts
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || ts.TagName || '%'
    LEFT JOIN 
        UserEngagement ue ON ue.UserId = p.OwnerUserId
    GROUP BY 
        ts.TagName
),
FinalReport AS (
    SELECT 
        tc.DisplayName,
        tc.TotalPosts,
        tc.QuestionCount,
        tc.AnswerCount,
        tc.AcceptedAnswers,
        tc.CommentCount,
        tc.TotalBounties,
        te.TagName,
        te.PostCount,
        te.QuestionCount AS TagQuestionCount,
        te.AcceptedQuestionCount
    FROM 
        TopContributors tc
    JOIN 
        TagEngagement te ON te.PostCount > 0
    ORDER BY 
        tc.Rank, te.TagName
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    TotalPosts > 10 -- Filter for users with significant engagement
ORDER BY 
    TagUsageCount DESC, DisplayName;
