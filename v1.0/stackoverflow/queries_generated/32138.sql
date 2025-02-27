WITH RECURSIVE UserBadgeCount AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
), 

UserPostActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,  -- Count of Upvotes
        SUM(V.VoteTypeId = 3) AS TotalDownvotes  -- Count of Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),

PostHistoryDetails AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        P.Title,
        PH.CreationDate,
        P.ViewCount,
        PH.Comment,
        P.Score,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags modification
),

UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UPA.PostCount, 0) AS PostCount,
        COALESCE(UPA.TotalUpvotes, 0) AS TotalUpvotes,
        COALESCE(UPA.TotalDownvotes, 0) AS TotalDownvotes,
        COUNT(PH.PostId) as EditCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 4 THEN 1 ELSE 0 END) AS TitleEdits
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCount UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        UserPostActivity UPA ON U.Id = UPA.UserId
    LEFT JOIN 
        PostHistoryDetails PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.BadgeCount,
    UPS.PostCount,
    UPS.TotalUpvotes,
    UPS.TotalDownvotes,
    UPS.EditCount,
    UPS.TitleEdits,
    CASE 
        WHEN UPS.BadgeCount > 10 THEN 'Prolific Contributor'
        WHEN UPS.EditCount > 20 THEN 'Active Editor'
        ELSE 'Regular User'
    END AS UserStatus
FROM 
    UserPostStats UPS
ORDER BY 
    UPS.BadgeCount DESC, UPS.PostCount DESC
LIMIT 10;

This SQL query performs a comprehensive analysis of users based on their badges, posts, activity, and contributions to edits across various posts. It leverages recursive CTEs, window functions, and outer joins to aggregate data and compute various metrics that provide insights into user engagement on the platform.
