WITH RECURSIVE UserPostCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags)-2), '><')::int[])
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 100
),
PostHistoryChanges AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12)  -- Closures, Reopenings, Deletions
)
SELECT 
    U.DisplayName,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    PT.TagPostCount AS PopularTagPostCount,
    CASE 
        WHEN PH.PostId IS NOT NULL THEN 'Modified'
        ELSE 'Unmodified'
    END AS PostModificationStatus
FROM 
    Users U
LEFT JOIN 
    UserPostCount UPC ON U.Id = UPC.UserId
LEFT JOIN 
    PopularTags PT ON PT.TagPostCount > 50  -- Joining with popular tags
LEFT JOIN 
    PostHistoryChanges PH ON U.Id = PH.PostId AND PH.rn = 1
WHERE 
    U.Reputation > 1000  -- Filter for users with a reputation greater than 1000
    AND (PT.TagPostCount IS NOT NULL OR UPC.PostCount > 0) -- Ensuring that there's a counting tag or post
ORDER BY 
    TotalPosts DESC, 
    PopularTagPostCount DESC
LIMIT 
    100;
