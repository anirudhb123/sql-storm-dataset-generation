WITH RecentTags AS (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount
    FROM 
        Tags 
    WHERE 
        Count > 0 
    GROUP BY 
        TagName
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        STRING_TO_ARRAY(P.Tags, ',') AS TagList ON TRUE
    JOIN 
        Tags T ON T.TagName = TRIM(BOTH '<>' FROM TagList)
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
    HAVING 
        P.Score > 10 AND P.ViewCount > 100
    ORDER BY 
        P.Score DESC
    LIMIT 10
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.TotalScore,
    PBS.Title AS PopularPostTitle,
    PBS.Score AS PopularPostScore,
    PBS.ViewCount AS PopularPostViewCount,
    PBS.Tags AS PopularPostTags,
    UBS.BadgeCount,
    UBS.Badges
FROM 
    UserPostStats UPS
LEFT JOIN 
    RecentTags RT ON RT.TagCount > 10
LEFT JOIN 
    PopularPosts PBS ON UPS.UserId = PBS.PostId
LEFT JOIN 
    UserBadgeStats UBS ON UBS.UserId = UPS.UserId
WHERE 
    UPS.PostCount > 5
ORDER BY 
    UPS.TotalScore DESC, UPS.PostCount DESC;
