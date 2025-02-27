WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes,
        SUM(V.VoteTypeId = 5) AS TotalFavorites
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts PT ON PT.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
ActiveUsers AS (
    SELECT 
        UserId,
        SUM(Te.TotalEngagement) AS EngagementScore
    FROM (
        SELECT 
            UserId,
            (TotalPosts + TotalComments + TotalUpVotes - TotalDownVotes + TotalFavorites) AS TotalEngagement
        FROM 
            UserEngagement
    ) Te
    GROUP BY 
        UserId
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalFavorites,
    COALESCE(Eng.EngagementScore, 0) AS EngagementScore,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM TopTags T) AS TopTags
FROM 
    UserEngagement U
LEFT JOIN 
    ActiveUsers Eng ON U.UserId = Eng.UserId
ORDER BY 
    EngagementScore DESC, U.TotalPosts DESC
LIMIT 15;
