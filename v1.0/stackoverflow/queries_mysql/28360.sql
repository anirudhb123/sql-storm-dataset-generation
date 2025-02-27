
WITH RecursiveTagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS JOIN (
        SELECT 
            a.N + b.N * 10 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
        CROSS JOIN 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b
    ) n
    WHERE 
        n.n <= 1 + LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) 
        AND PostTypeId = 1  
    GROUP BY 
        TagName
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
