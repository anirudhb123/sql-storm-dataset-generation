
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag 
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
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
        COUNT(*) > 10  
),
PostViewStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        pt.Tag AS MostCommonTag,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        PostTags pt ON p.Id = pt.PostId
    JOIN 
        TagsWithCount t ON pt.Tag = t.Tag
    WHERE 
        p.PostTypeId = 1 
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
        u.Reputation > 10  
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalViews,
        ue.TotalAnswers,
        ue.TotalScore,
        ue.BadgeCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserEngagement ue, (SELECT @rank := 0) r
    ORDER BY 
        ue.TotalScore DESC
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
    t.Rank <= 10  
ORDER BY 
    t.Rank;
