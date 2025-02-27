WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
), PostHistories AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '6 months'
        AND PH.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted
    GROUP BY 
        PH.UserId, PH.PostId, PH.PostHistoryTypeId 
), QualifiedUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        UReputation.ReputationRank,
        COALESCE(RP.PostCount, 0) AS RecentPostCount,
        COALESCE(RP.TotalScore, 0) AS RecentTotalScore,
        COALESCE(RP.AvgViews, 0) AS RecentAvgViews,
        PH.HistoryCount
    FROM 
        UserReputation U
    LEFT JOIN 
        RecentPosts RP ON U.UserId = RP.OwnerUserId
    LEFT JOIN 
        PostHistories PH ON U.UserId = PH.UserId
    WHERE 
        UReputation.ReputationRank <= 5
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.RecentPostCount,
    U.RecentTotalScore,
    U.RecentAvgViews,
    CASE 
        WHEN U.HistoryCount IS NULL THEN 'No history'
        ELSE CAST(U.HistoryCount AS VARCHAR) || ' changes'
    END AS PostHistoryInfo,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    QualifiedUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, '<>')) AS TagName
    ) T ON TRUE
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.RecentPostCount, U.RecentTotalScore, U.RecentAvgViews, U.HistoryCount
ORDER BY 
    U.Reputation DESC, U.RecentPostCount DESC
LIMIT 100;

This query combines several SQL constructs including Common Table Expressions (CTEs) to build layers of data, with outer joins for optional data inclusion. It utilizes window functions for ranking, aggregates to summarize posts and history changes, along with a lateral join for extracting associated tags. The conditions and calculations aim to filter users based on their reputation and activity, while removing NULL logic and embracing the complexity of the schema and dataset.
