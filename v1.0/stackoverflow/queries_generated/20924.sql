WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title,
        P.OwnerUserId, 
        P.CreationDate, 
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.ViewCount IS NOT NULL AND 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL OR U.Reputation = 0 THEN 'No reputation available'
            ELSE 'Reputation Score: ' || U.Reputation::text
        END AS ReputationInfo
    FROM 
        Users U 
    WHERE 
        EXISTS (
            SELECT 1 
            FROM Posts P 
            WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 1
        )
),
PostHistoryAggregation AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (5, 4) -- Edit Body and Edit Title
    GROUP BY 
        PH.PostId, PH.UserId
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(PH.EditCount, 0) AS EditCount,
        P.ViewCount,
        P.Score,
        P.Title,
        P.OwnerUserId
    FROM 
        Posts P 
    LEFT JOIN 
        PostHistoryAggregation PH ON P.Id = PH.PostId
    WHERE 
        P.Score > 10
    ORDER BY 
        P.ViewCount DESC
    LIMIT 50
)

SELECT 
    U.DisplayName, 
    U.Reputation, 
    FP.PostId, 
    FP.Title, 
    FP.ViewCount, 
    FP.EditCount,
    CASE
        WHEN FP.EditCount > 0 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    R.PostId AS RecentPostId,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    R.ViewCount AS RecentPostViews
FROM 
    FilteredUsers U
JOIN 
    PopularPosts FP ON U.Id = FP.OwnerUserId
LEFT JOIN 
    RankedPosts R ON U.Id = R.OwnerUserId AND R.RN = 1
WHERE 
    U.Reputation BETWEEN 100 AND 10000 
    AND U.Location IS NOT NULL
ORDER BY 
    U.Reputation DESC, 
    FP.ViewCount DESC;

This SQL query is designed to extract insightful information about users and their posts over the last year, incorporating complexities such as CTEs, window functions, conditional expressions, and outer joins. The result gives a detailed overview of user engagement through posts, capturing both current performance and recent activities creatively with the inclusion of corner cases in the calculation and decision logic.
