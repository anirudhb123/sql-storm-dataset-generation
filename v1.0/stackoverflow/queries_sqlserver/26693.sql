
WITH TagPostCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts, 
        STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS TagName
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
RecentActivity AS (
    SELECT 
        U.DisplayName,
        COUNT(CASE WHEN P.LastActivityDate >= DATEADD(DAY, -30, GETDATE()) THEN 1 END) AS RecentActivityCount,
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
        ROW_NUMBER() OVER (PARTITION BY T.TagName ORDER BY PC.PostCount DESC) AS TagRank
    FROM 
        Tags AS T
    JOIN 
        TagPostCounts AS PC ON T.TagName = PC.TagName
    LEFT JOIN 
        RecentActivity AS R ON R.DisplayName = T.TagName 
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
