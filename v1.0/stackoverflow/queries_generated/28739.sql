WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only consider questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
),
UserContribution AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        UC.PostCount,
        UC.TotalViews,
        UC.TotalScore,
        UC.QuestionCount,
        UC.AnswerCount
    FROM 
        Users U
    JOIN 
        UserContribution UC ON U.Id = UC.UserId
    WHERE 
        U.LastAccessDate >= NOW() - INTERVAL '1 year' -- Users active in the last year
),
TopContributors AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        A.Reputation,
        A.PostCount,
        A.TotalViews,
        A.TotalScore,
        RANK() OVER (ORDER BY A.TotalScore DESC) AS ScoreRank
    FROM 
        ActiveUsers A
    WHERE 
        A.PostCount > 0
),
TagAnalysis AS (
    SELECT 
        T.Tag,
        COUNT(P.Id) AS RelatedPosts,
        SUM(P.ViewCount) AS TotalViewCount,
        SUM(P.Score) AS TotalScore
    FROM 
        TopTags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.Tag || '%'
    WHERE 
        P.PostTypeId != 4  -- Exclude tag wikis
    GROUP BY 
        T.Tag
)
SELECT 
    TC.DisplayName AS TopContributor,
    TC.TotalScore AS ContributorScore,
    TA.Tag AS AssociatedTag,
    TA.RelatedPosts,
    TA.TotalViewCount,
    TA.TotalScore AS TagScore
FROM 
    TopContributors TC
JOIN 
    TagAnalysis TA ON TA.TotalScore > 0
ORDER BY 
    TC.ScoreRank, TA.TotalScore DESC
LIMIT 10;
