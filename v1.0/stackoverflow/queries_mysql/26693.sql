
WITH TagPostCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users AS U
    JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        AnswerCount DESC
    LIMIT 10
),
RecentActivity AS (
    SELECT 
        U.DisplayName,
        COUNT(CASE WHEN P.LastActivityDate >= NOW() - INTERVAL 30 DAY THEN 1 END) AS RecentActivityCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostsCount
    FROM 
        Users AS U
    JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.DisplayName
),
TagDetails AS (
    SELECT 
        T.TagName,
        PC.PostCount,
        R.RecentActivityCount,
        R.PopularPostsCount,
        @row_number := IF(@current_tag = T.TagName, @row_number + 1, 1) AS TagRank,
        @current_tag := T.TagName
    FROM 
        Tags AS T
    JOIN 
        TagPostCounts AS PC ON T.TagName = PC.TagName
    LEFT JOIN 
        RecentActivity AS R ON R.DisplayName = T.TagName,
        (SELECT @row_number := 0, @current_tag := '') AS vars
    ORDER BY 
        T.TagName, PC.PostCount DESC
)
SELECT 
    TD.TagName,
    TD.PostCount,
    TD.RecentActivityCount,
    TD.PopularPostsCount
FROM 
    TagDetails AS TD
WHERE 
    TD.TagRank = 1
ORDER BY 
    TD.PostCount DESC
LIMIT 10;
