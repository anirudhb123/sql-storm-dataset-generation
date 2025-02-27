WITH TagOccurrence AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagOccurrence
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.AnswersProvided,
    ua.TotalViews,
    ua.TotalScore,
    pt.Tag,
    pt.PostCount AS TagPostCount,
    ua.LastBadgeDate
FROM 
    UserActivity ua
JOIN 
    PopularTags pt ON pt.Rank <= 5
ORDER BY 
    ua.TotalScore DESC, 
    ua.QuestionsAsked DESC, 
    pt.PostCount DESC;

