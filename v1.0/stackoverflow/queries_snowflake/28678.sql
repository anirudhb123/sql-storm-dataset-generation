
WITH TagStats AS (
    SELECT 
        TRIM(SPLIT_PART(Tags, '><', n)) AS TagName,
        COUNT(*) AS PostCount,
        COUNT(DISTINCT OwnerUserId) AS UniqueUserCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SEQUENCE(1, ARRAY_SIZE(SPLIT(Tags, '><')))) AS n
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SPLIT_PART(Tags, '><', n))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        UniqueUserCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 10 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.TagName,
    t.PostCount,
    t.UniqueUserCount,
    u.UserId,
    u.DisplayName AS MostActiveUser,
    u.QuestionsAsked,
    u.UpvotedQuestions,
    u.TotalViews
FROM 
    TopTags t
JOIN 
    UserStats u ON u.QuestionsAsked = (
        SELECT MAX(QuestionsAsked)
        FROM UserStats
        WHERE QuestionsAsked > 0
    )
WHERE 
    t.Rank <= 5 
ORDER BY 
    t.Rank,
    u.TotalViews DESC;
