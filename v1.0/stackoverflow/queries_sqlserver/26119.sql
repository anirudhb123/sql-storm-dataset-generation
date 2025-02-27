
WITH TagUsage AS (
    SELECT 
        VALUE AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        VALUE
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        PostCount > 5  
),
UserContributions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS ContributionCount,
        SUM(ISNULL(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        ContributionCount,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY ContributionCount DESC) AS ContributionRank
    FROM 
        UserContributions
    WHERE 
        ContributionCount > 10 
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TC.DisplayName AS TopContributor,
    TC.ContributionCount,
    TC.TotalViews
FROM 
    TopTags TT
LEFT JOIN 
    TopContributors TC ON TC.ContributionCount = (
        SELECT MAX(ContributionCount)
        FROM TopContributors
        WHERE UserId IN (
            SELECT DISTINCT P.OwnerUserId
            FROM Posts P
            WHERE P.Tags LIKE '%' + TT.TagName + '%'
        )
    )
ORDER BY 
    TT.TagRank, TC.ContributionCount DESC;
