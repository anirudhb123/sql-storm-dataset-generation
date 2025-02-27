WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS BountyRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalComments, 
        Questions, 
        Answers, 
        TotalBounty,
        BountyRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0
    ORDER BY 
        TotalBounty DESC
    LIMIT 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_id ON TRUE
    LEFT JOIN 
        Tags t ON t.Id = tag_id::int
    GROUP BY 
        p.Id
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.Questions,
    tu.Answers,
    tu.TotalBounty,
    pt.Tags
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
ORDER BY 
    tu.BountyRank;
