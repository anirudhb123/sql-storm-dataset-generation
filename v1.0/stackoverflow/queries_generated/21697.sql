WITH RecursivePostHistory AS (
    SELECT
        PH.Id,
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.UserId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        U.DisplayName AS OwnerDisplayName,
        PH.PostHistoryTypeId,
        PH.CreationDate AS ChangeDate,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed' 
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE NULL 
        END AS Status
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        RecursivePostHistory PH ON PH.PostId = P.Id
    WHERE
        P.CreationDate > (SELECT MAX(CreationDate) - INTERVAL '365 days' FROM Posts) -- Posts in the last year
        AND (PH.PostHistoryTypeId IS NOT NULL)
),
AggregateStatus AS (
    SELECT
        PostId,
        COUNT(*) FILTER (WHERE Status = 'Closed') AS ClosedCount,
        COUNT(*) FILTER (WHERE Status = 'Reopened') AS ReopenedCount,
        COUNT(*) AS TotalChanges
    FROM
        PostDetails
    GROUP BY
        PostId
),
UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.Score, 0)) AS TotalComments,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY
        U.Id
),
FinalReport AS (
    SELECT 
        DA.OwnerDisplayName,
        AS.CompletedCount AS ProjectCount,
        UA.PostsCount AS UserPostCount,
        UA.TotalViews AS TotalPostViews,
        UA.TotalComments AS UserCommentsCount,
        COALESCE(AS.ClosedCount, 0) AS PostClosedCount,
        COALESCE(AS.ReopenedCount, 0) AS PostReopenedCount,
        ((COALESCE(AS.ClosedCount, 0) + COALESCE(AS.ReopenedCount, 0))::decimal / NULLIF(COALESCE(AS.TotalChanges, 1), 0)) * 100 AS ClosureRatePercent
    FROM
        AggregateStatus AS
    JOIN
        PostDetails DA ON AS.PostId = DA.PostId
    JOIN
        UserEngagement UA ON DA.OwnerDisplayName = UA.DisplayName
)
SELECT
    *
FROM 
    FinalReport
WHERE 
    UserPostCount > 10
ORDER BY 
    ClosureRatePercent DESC, TotalPostViews DESC;

This query contains various SQL constructs tailored for performance benchmarking in a complex schema, including:

- Common Table Expressions (CTEs) for organizing data intelligently from `PostHistory`, `Posts`, and `Users`.
- Usage of window functions (`ROW_NUMBER`) to manage recursive relationships in post history.
- Filters and aggregates for evaluating user engagement and post history changes with bizarre incorporation of closure metrics.
- Explicit NULL handling through `COALESCE` combined with `NULLIF` to ensure safe arithmetic operations, avoiding undesirable divide-by-zero.
- Final selection criteria focused on users with a set number of posts, demonstrating complex predicates.
