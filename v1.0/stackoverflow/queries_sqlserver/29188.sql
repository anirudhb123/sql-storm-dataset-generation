
WITH PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '>') AS Tag
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  
), PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5  
), TagDetails AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count AS TotalUsage,
        P.Title AS ExamplePostTitle,
        P.CreationDate AS ExamplePostDate,
        U.DisplayName AS ExampleUser
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        T.TagName IN (SELECT Tag FROM PopularTags)
    ORDER BY 
        T.Count DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY  
), RecentPostActivities AS (
    SELECT 
        PH.PostId, 
        PH.UserId, 
        PH.CreationDate,
        P.Title,
        P.OwnerDisplayName,
        P.AcceptedAnswerId,
        PH.Comment
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days'  
    ORDER BY 
        PH.CreationDate DESC
)
SELECT 
    TD.TagName,
    TD.TotalUsage,
    TD.ExamplePostTitle,
    TD.ExamplePostDate,
    TD.ExampleUser,
    COUNT(RPA.PostId) AS RecentActivityCount
FROM 
    TagDetails TD
LEFT JOIN 
    RecentPostActivities RPA ON TD.TagName LIKE '%' + RPA.Title + '%'
GROUP BY 
    TD.TagName, TD.TotalUsage, TD.ExamplePostTitle, TD.ExamplePostDate, TD.ExampleUser
ORDER BY 
    COUNT(RPA.PostId) DESC, TD.TotalUsage DESC;
