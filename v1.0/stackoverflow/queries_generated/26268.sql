WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag 
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only considering questions
), 
TagsWithCount AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount 
    FROM 
        PostTags 
    GROUP BY 
        Tag 
    HAVING 
        COUNT(*) > 10  -- Only consider tags with more than 10 questions
),
PostViewStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        pt.Tag AS MostCommonTag
    FROM 
        Posts p
    JOIN 
        PostTags pt ON p.Id = pt.PostId
    JOIN 
        TagsWithCount t ON pt.Tag = t.Tag
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    WHERE 
        u.Reputation > 10  -- Only include users with reputation greater than 10
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalViews,
        ue.TotalAnswers,
        ue.TotalScore,
        ue.BadgeCount,
        RANK() OVER (ORDER BY ue.TotalScore DESC) AS Rank
    FROM 
        UserEngagement ue
)
SELECT 
    t.DisplayName AS Username,
    t.TotalViews,
    t.TotalAnswers,
    t.TotalScore,
    p.Title AS MostViewedPostTitle,
    p.ViewCount AS MostViewedPostCount,
    t.BadgeCount
FROM 
    TopUsers t
LEFT JOIN 
    PostViewStats p ON t.UserId = p.OwnerUserId
WHERE 
    t.Rank <= 10  -- Top 10 users
ORDER BY 
    t.Rank;
