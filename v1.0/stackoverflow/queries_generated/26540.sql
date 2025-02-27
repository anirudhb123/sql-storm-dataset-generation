WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount,
        (SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.UserId = U.Id AND V.VoteTypeId IN (8, 9)) AS TotalBounty
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),

TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),

PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        PH.UserId AS LastEditorId,
        PH.UserDisplayName AS LastEditorName,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.UserId, PH.UserDisplayName
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    U.TotalBounty,
    TS.TagName,
    TS.PostCount AS TagPostCount,
    TS.TotalViews,
    TS.AverageScore,
    PHS.LastEditorName,
    PHS.LastEditDate,
    PHS.CloseReopenCount,
    PHS.DeleteUndeleteCount
FROM 
    UserStats U
JOIN 
    TagStats TS ON TS.PostCount > 50
JOIN 
    PostHistorySummary PHS ON PHS.LastEditorId = U.UserId
ORDER BY 
    U.Reputation DESC, 
    TS.AverageScore DESC;
