
WITH RecursiveTagCounts AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(Tags, '<([^>]+)>', 1, seq.i)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => LENGTH(Tags) - LENGTH(REPLACE(Tags, '>', '')))) AS seq
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(REGEXP_SUBSTR(Tags, '<([^>]+)>', 1, seq.i))
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 100  
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        RecursiveTagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10  
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.TotalComments,
    AU.TotalBounties,
    PT.TagName,
    PT.PostCount
FROM 
    ActiveUsers AU
JOIN 
    PopularTags PT ON AU.TotalPosts > 5  
ORDER BY 
    AU.TotalBounties DESC, AU.TotalPosts DESC;
