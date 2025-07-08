
WITH PostTags AS (
    SELECT 
        P.Id AS PostId,
        SPLIT(TRIM(BOTH ' ' FROM SUBSTR(P.Tags, 2, LENGTH(P.Tags) - 2)), '><') AS Tag
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
        Posts P ON POSITION(T.TagName IN P.Tags) > 0
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        T.TagName IN (SELECT Tag FROM PopularTags)
    ORDER BY 
        T.Count DESC
    LIMIT 10  
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
        PH.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56'::TIMESTAMP)  
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
    RecentPostActivities RPA ON POSITION(TD.TagName IN RPA.Title) > 0
GROUP BY 
    TD.TagName, TD.TotalUsage, TD.ExamplePostTitle, TD.ExamplePostDate, TD.ExampleUser
ORDER BY 
    COUNT(RPA.PostId) DESC, TD.TotalUsage DESC;
