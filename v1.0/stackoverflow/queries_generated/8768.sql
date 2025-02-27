WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        Wikis,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts PT ON PT.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10 
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalViews,
    SUM(PTC.PostCount) AS TotalPostTags,
    PTC.TagName
FROM 
    TopUsers TU
JOIN 
    PostLinks PL ON TU.UserId = PL.PostId
JOIN 
    PopularTags PTC ON PL.RelatedPostId = PTC.PostId
WHERE 
    TU.ReputationRank <= 50
GROUP BY 
    TU.DisplayName, TU.Reputation, TU.TotalPosts, TU.TotalViews, PTC.TagName
ORDER BY 
    TU.Reputation DESC, TotalPostTags DESC
LIMIT 100;
