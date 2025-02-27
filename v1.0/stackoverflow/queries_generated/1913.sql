WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount, 
        MAX(Date) AS LastBadgeDate 
    FROM 
        Badges 
    GROUP BY 
        UserId
), 
PostStats AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS TotalPosts, 
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions, 
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers 
    FROM 
        Posts 
    GROUP BY 
        OwnerUserId
), 
CommentStats AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalComments 
    FROM 
        Comments 
    GROUP BY 
        UserId
), 
TopUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(UB.BadgeCount, 0) AS BadgeCount, 
        COALESCE(PS.TotalPosts, 0) AS TotalPosts, 
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions, 
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(CS.TotalComments, 0) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        CommentStats CS ON U.Id = CS.UserId
)
SELECT 
    DisplayName,
    Reputation,
    BadgeCount,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalComments,
    RANK() OVER (ORDER BY Reputation DESC) AS Rank
FROM 
    TopUsers
WHERE 
    Reputation > 1000
ORDER BY 
    Rank
LIMIT 10;

SELECT 
    DISTINCT COALESCE(TR.TagName, 'No Tags') AS TagName, 
    COUNT(P.Id) AS PostCount
FROM 
    Posts P
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><')) AS TagName
LEFT JOIN 
    Tags TR ON TR.TagName = TagName
GROUP BY 
    TR.TagName
HAVING 
    COUNT(P.Id) > 5
ORDER BY 
    PostCount DESC
LIMIT 10;
