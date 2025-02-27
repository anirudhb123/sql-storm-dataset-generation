WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only consider questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5 -- Only tags with more than 5 posts
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(ph.Comment IS NOT NULL), 0) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Get only questions
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId AND ph.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalBounty,
        EditCount
    FROM 
        UserActivity
    WHERE 
        QuestionCount > 0
)
SELECT 
    t.Tag,
    t.PostCount,
    a.DisplayName,
    a.QuestionCount,
    a.TotalBounty,
    a.EditCount
FROM 
    TopTags t
JOIN 
    Posts p ON t.Tag = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
JOIN 
    ActiveUsers a ON p.OwnerUserId = a.UserId
ORDER BY 
    t.PostCount DESC,
    a.TotalBounty DESC;
