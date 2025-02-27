WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalViews
    FROM 
        RankedUsers
    WHERE 
        ReputationRank <= 10
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.PostId) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalViews,
    pt.TagName AS PopularTag,
    pt.PostCount AS RelatedPostCount,
    pt.TotalViews AS TagTotalViews,
    ua.CommentCount AS UserCommentCount,
    ua.EditCount AS UserEditCount
FROM 
    TopUsers tu
JOIN 
    UserActivity ua ON tu.UserId = ua.UserId
JOIN 
    PopularTags pt ON tu.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Tags ILIKE '%' || pt.TagName || '%')
ORDER BY 
    tu.Reputation DESC, pt.PostCount DESC;
