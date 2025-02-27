WITH TagStatistics AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN ViewCount > 100 THEN 1 ELSE 0 END) AS PopularityCount,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(COALESCE(B.Count, 0)) AS TotalBadges,
        SUM(UPV.VoteCount) AS TotalVotes,
        SUM(COALESCE(CR.CriterionCount, 0)) AS ClosedPostsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) AS UPV ON UPV.PostId = P.Id
    LEFT JOIN (
        SELECT 
            PH.UserId, COUNT(*) AS CriterionCount
        FROM 
            PostHistory PH
        WHERE 
            PH.PostHistoryTypeId IN (10, 11) -- Closed & Reopened
        GROUP BY 
            PH.UserId
    ) AS CR ON CR.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        PopularityCount,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) as TagRank
    FROM 
        TagStatistics
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.QuestionCount,
    U.TotalBadges,
    U.TotalVotes,
    U.ClosedPostsCount,
    T.TagName,
    T.PostCount,
    T.PopularityCount,
    T.AverageScore
FROM 
    UserActivity U
JOIN 
    TopTags T ON U.QuestionCount > 0
WHERE 
    T.TagRank <= 5
ORDER BY 
    U.TotalVotes DESC, T.PostCount DESC;
