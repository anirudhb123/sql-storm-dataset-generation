WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.OwnerUserId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.OwnerUserId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserReputationSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 END) AS EditSuggestionCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
FinalPostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CancellationCount,
        PH.EditSuggestionCount,
        UFC.UpvoteCount,
        UFC.DownvoteCount,
        URS.DisplayName AS OwnerDisplayName,
        URS.Reputation AS OwnerReputation,
        RPH.Level AS PostLevel
    FROM 
        Posts P
    LEFT JOIN 
        PostHistoryAggregates PH ON P.Id = PH.PostId
    LEFT JOIN 
        PostVoteCounts UFC ON P.Id = UFC.PostId
    LEFT JOIN 
        Users URS ON P.OwnerUserId = URS.Id
    LEFT JOIN 
        RecursivePostHierarchy RPH ON P.Id = RPH.PostId
)

SELECT 
    FPM.PostId,
    FPM.Title,
    FPM.OwnerDisplayName,
    FPM.OwnerReputation,
    FPM.UpvoteCount,
    FPM.DownvoteCount,
    FPM.CancellationCount,
    FPM.EditSuggestionCount,
    FPM.PostLevel,
    CASE 
        WHEN FPM.CancellationCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount
FROM 
    FinalPostMetrics FPM
LEFT JOIN 
    Comments C ON C.PostId = FPM.PostId
GROUP BY 
    FPM.PostId, FPM.Title, FPM.OwnerDisplayName, FPM.OwnerReputation, FPM.UpvoteCount, 
    FPM.DownvoteCount, FPM.CancellationCount, FPM.EditSuggestionCount, FPM.PostLevel
ORDER BY 
    FPM.UpvoteCount DESC, FPM.DownvoteCount ASC
LIMIT 100;
