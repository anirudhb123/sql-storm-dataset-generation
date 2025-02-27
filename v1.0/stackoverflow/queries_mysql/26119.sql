
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT a.N + b.N * 10 + 1 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @tagRank := @tagRank + 1 AS TagRank
    FROM 
        TagUsage, (SELECT @tagRank := 0) r
    WHERE 
        PostCount > 5  
),
UserContributions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS ContributionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
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
        @contribRank := @contribRank + 1 AS ContributionRank
    FROM 
        UserContributions, (SELECT @contribRank := 0) r
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
            WHERE P.Tags LIKE CONCAT('%', TT.TagName, '%')
        )
    )
ORDER BY 
    TT.TagRank, TC.ContributionCount DESC;
