WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotes,
        TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    pt.TagName,
    pt.TagCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT 
            UNNEST(STRING_TO_ARRAY(p.Tags, ',')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.UserId 
            AND p.PostTypeId = 1
    )
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.Reputation DESC, pt.TagCount DESC;
