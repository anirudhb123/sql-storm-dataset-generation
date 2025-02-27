WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AcceptedAnswerId,
        P.OwnerUserId,
        0 AS Level,
        CAST(P.Title AS VARCHAR(MAX)) AS Hierarchy
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Starting point for questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.ViewCount,
        P2.AcceptedAnswerId,
        P2.OwnerUserId,
        Level + 1,
        CAST(RPH.Hierarchy + ' -> ' + P2.Title AS VARCHAR(MAX))
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy RPH ON P2.ParentId = RPH.PostId
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    SUM(P.ViewCount) AS TotalViews,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    MAX(P.CreationDate) AS LastActive,
    STRING_AGG(T.TagName, ', ') AS Tags,
    CASE 
        WHEN COUNT(DISTINCT PH.PostId) > 0 THEN 'Active Contributor'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)  -- counting closed/opened posts
LEFT JOIN 
    LATERAL (
        SELECT 
            T.TagName
        FROM 
            UNNEST(STRING_TO_ARRAY(P.Tags, ',')) AS T(TagName)
    ) AS T ON TRUE
WHERE 
    U.Reputation > 1000  -- only consider users with a reputation greater than 1000
GROUP BY 
    U.Id
HAVING 
    SUM(P.ViewCount) > 5000 -- only include users with a total view count over 5000
ORDER BY 
    TotalViews DESC;

WITH TagStats AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        (SELECT 
            UNNEST(STRING_TO_ARRAY(Posts.Tags, ',')) AS TagName,
            Posts.Id AS PostId,
            Posts.ViewCount
        FROM 
            Posts) AS sub
    GROUP BY 
        TagName
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    RANK() OVER (ORDER BY TS.TotalViews DESC) AS RankByViews,
    DENSE_RANK() OVER (ORDER BY TS.PostCount DESC) AS RankByPostCount
FROM 
    TagStats TS
WHERE 
    TS.PostCount > 10 -- Only tags that have more than 10 associated posts
ORDER BY 
    RankByViews, RankByPostCount;

