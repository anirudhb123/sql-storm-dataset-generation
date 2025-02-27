
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        CommentCount,
        BadgeCount,
        (SELECT COUNT(*) FROM UserActivity UA WHERE UA.TotalScore > U.TotalScore) + 1 AS ScoreRank,
        (SELECT COUNT(*) FROM UserActivity UA WHERE UA.TotalViews > U.TotalViews) + 1 AS ViewRank
    FROM 
        UserActivity U
)

SELECT 
    T.DisplayName,
    T.PostCount,
    T.TotalViews,
    T.TotalScore,
    T.CommentCount,
    T.BadgeCount,
    COALESCE(CASE 
        WHEN ScoreRank < 10 THEN 'Top Scorer' 
        ELSE NULL END, 
    CASE 
        WHEN ViewRank < 10 THEN 'Top Viewer' 
        ELSE NULL END) AS Recognition,
    CASE 
        WHEN T.BadgeCount > 5 THEN 'Frequent Contributor'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers T
WHERE 
    T.TotalScore > 0
ORDER BY 
    T.TotalScore DESC, T.TotalViews DESC;
