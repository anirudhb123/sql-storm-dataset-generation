
WITH PostTags AS (
    SELECT 
        P.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts P
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t, (SELECT @row := 0) r) n
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
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
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
        PH.CreationDate >= NOW() - INTERVAL 30 DAY  
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
    RecentPostActivities RPA ON TD.TagName LIKE CONCAT('%', RPA.Title, '%')
GROUP BY 
    TD.TagName, TD.TotalUsage, TD.ExamplePostTitle, TD.ExamplePostDate, TD.ExampleUser
ORDER BY 
    COUNT(RPA.PostId) DESC, TD.TotalUsage DESC;
