WITH RecursivePostPaths AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ParentId,
        RP.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostPaths RP ON P.ParentId = RP.PostId
),
UserReputationSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPostStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.PostId) AS ClosedCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(CPS.ClosedCount, 0) AS ClosedPosts,
    COALESCE(CPS.LastClosedDate, 'N/A') AS LastClosedPost,
    COALESCE(UPS.TotalBounty, 0) AS TotalBounty,
    UPS.BadgeCount,
    RPP.PostId AS RelatedPostId,
    RPP.Title AS RelatedPostTitle,
    RPP.CreationDate AS RelatedPostCreationDate,
    RPP.Level AS PostLevel
FROM 
    Users U
LEFT JOIN 
    ClosedPostStats CPS ON U.Id = CPS.UserId
LEFT JOIN 
    UserReputationSummary UPS ON U.Id = UPS.UserId
LEFT JOIN 
    RecursivePostPaths RPP ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = RPP.PostId)
WHERE 
    U.Reputation >= (
        SELECT 
            AVG(Reputation) 
        FROM 
            Users 
        WHERE 
            CreationDate < NOW() - INTERVAL '1 year'
    )
ORDER BY 
    U.Reputation DESC, 
    RPP.Level asc;
