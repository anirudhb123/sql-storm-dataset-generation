WITH UserScoreCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostSummaryCTE AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CloseReasonAggregate AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(CONCAT(CAST(PH.Comment AS varchar), ' (', PH.CreationDate::date, ')'), '; ') AS CloseReasons
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.UserId
),
FinalSummary AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COALESCE(US.TotalPosts, 0) AS TotalPosts,
        COALESCE(US.PositivePosts, 0) AS PositivePosts,
        COALESCE(US.NegativePosts, 0) AS NegativePosts,
        COALESCE(US.AverageScore, 0) AS AverageScore,
        COALESCE(CA.CloseReasonCount, 0) AS CloseReasonCount,
        COALESCE(CA.CloseReasons, 'No closures') AS CloseReasons
    FROM Users U
    LEFT JOIN PostSummaryCTE US ON U.Id = US.OwnerUserId
    LEFT JOIN CloseReasonAggregate CA ON U.Id = CA.UserId
)
SELECT 
    *,
    CASE 
        WHEN Reputation >= 1000 THEN 'Veteran'
        WHEN Reputation >= 500 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserCategory,
    ARRAY_AGG(DISTINCT T.TagName) FILTER (WHERE T.TagName IS NOT NULL) AS AssociatedTags
FROM FinalSummary FS
LEFT JOIN Posts P ON FS.UserId = P.OwnerUserId
LEFT JOIN LATERAL (
    SELECT DISTINCT TRIM(UNNEST(string_to_array(P.Tags, ','))) AS TagName
) T ON true
GROUP BY FS.DisplayName, FS.Reputation, FS.TotalPosts, FS.PositivePosts, FS.NegativePosts, FS.AverageScore, FS.CloseReasonCount, FS.CloseReasons
ORDER BY FS.Reputation DESC, FS.TotalPosts DESC
LIMIT 50;
