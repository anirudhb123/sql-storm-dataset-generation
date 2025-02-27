WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        TotalPosts, 
        TotalComments, 
        QuestionCount, 
        AnswerCount, 
        TotalBounties,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserActivity
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ARRAY_POSITION(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), t.TagName)
    GROUP BY 
        t.TagName
)
SELECT 
    tu.DisplayName AS TopUserDisplayName,
    tu.Reputation AS TopUserReputation,
    tu.TotalPosts AS TopUserTotalPosts,
    ts.TagName AS PopularTag,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews,
    ts.Questions AS TagQuestionCount,
    ts.Answers AS TagAnswerCount
FROM 
    TopUsers tu
JOIN 
    TagStatistics ts ON ts.PostCount > 10
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC, ts.PostCount DESC;
