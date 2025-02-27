WITH TagStats AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalAnswers,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStats
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
UserEngagement AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        A.PostCount,
        A.Reputation,
        A.TotalBounty,
        T.TagName,
        T.PostCount AS TagPostCount,
        T.TotalAnswers,
        T.TotalViews,
        T.AverageScore
    FROM 
        ActiveUsers A
    JOIN 
        Posts P ON A.UserId = P.OwnerUserId
    JOIN 
        LATERAL (
            SELECT 
                UNNEST(STRING_TO_ARRAY(P.Tags, '>')) AS TagName
        ) AS T ON TRUE
    JOIN 
        TopTags T ON T.TagName = TRIM(BOTH '<>' FROM T.TagName)
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    SUM(U.TotalBounty) AS TotalBounty,
    COUNT(DISTINCT U.TagName) AS UniqueTags,
    SUM(U.TotalAnswers) AS TotalAnswers,
    SUM(U.TotalViews) AS TotalViews,
    AVG(U.AverageScore) AS AverageScore
FROM 
    UserEngagement U
GROUP BY 
    U.DisplayName, U.Reputation, U.PostCount
ORDER BY 
    TotalBounty DESC, TotalViews DESC
LIMIT 10;
