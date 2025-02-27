WITH UserScoreCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 END), 0) AS VoteScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(V.CreationDate), 0) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
RecentPostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
ClosedPostsCTE AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
        AND PH.CreationDate > CURRENT_DATE - INTERVAL '90 days'
    GROUP BY 
        PH.PostId
),
TagSummary AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    U.Views AS UserViews,
    RS.PostTitle,
    RS.PostCreationDate,
    COALESCE(CP.ClosedCount, 0) AS RecentClosedPosts,
    TS.TagName AS PopularTag,
    TS.PostCount AS TagPostCount,
    TS.TotalViews AS TagTotalViews,
    CASE 
        WHEN U.Reputation > 1000 THEN 'Top Contributor'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorType,
    STRING_AGG(DISTINCT concat(TS.TagName, ': ', TS.TotalViews), '; ') AS TagDetails
FROM 
    UserScoreCTE U
LEFT JOIN 
    RecentPostCTE RS ON RS.OwnerUserId = U.UserId AND RS.PostRank = 1
LEFT JOIN 
    ClosedPostsCTE CP ON CP.PostId = RS.PostId
LEFT JOIN 
    TagSummary TS ON TS.PostCount > 0
WHERE 
    U.VoteScore > 0
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.Views, RS.PostTitle, RS.PostCreationDate, CP.ClosedCount
HAVING 
    COUNT(DISTINCT TS.TagName) > 3
ORDER BY 
    U.Reputation DESC NULLS LAST, 
    UserDisplayName ASC
LIMIT 100 OFFSET 0;
