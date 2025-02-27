WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Considering only questions for tag analysis
    GROUP BY 
        TagName
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- counts of questions
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'  -- users created in the last year
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        ROW_NUMBER() OVER (ORDER BY tc.PostCount DESC) AS Rank
    FROM 
        TagCounts tc
    WHERE 
        tc.PostCount > 5  -- Only tags with more than 5 posts
),
TopUsers AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.QuestionCount,
        au.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY au.QuestionCount DESC) AS Rank
    FROM 
        ActiveUsers au
    WHERE 
        au.QuestionCount > 0
)
SELECT 
    t.TagName,
    t.PostCount,
    u.DisplayName AS TopUser,
    u.QuestionCount,
    u.TotalBounty
FROM 
    TopTags t
LEFT JOIN 
    TopUsers u ON u.Rank = 1  -- Join to get top user for each tag
ORDER BY 
    t.PostCount DESC, u.TotalBounty DESC;
