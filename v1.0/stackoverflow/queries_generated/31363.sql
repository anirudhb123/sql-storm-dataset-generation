WITH RecursivePostHistory AS (
    SELECT 
        Ph.Id AS HistoryId,
        Ph.PostId,
        Ph.CreationDate,
        Ph.UserId,
        Ph.Comment,
        Ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11)  -- Looking for closed and reopened posts
    UNION ALL
    SELECT 
        Ph.Id,
        Ph.PostId,
        Ph.CreationDate,
        Ph.UserId,
        Ph.Comment,
        Ph.PostHistoryTypeId,
        Level + 1
    FROM 
        PostHistory Ph
    JOIN 
        RecursivePostHistory RPh ON RPh.PostId = Ph.PostId
    WHERE 
        RPh.UserId != Ph.UserId AND RPh.Level < 5  -- Limiting recursion depth and excluding same user actions
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(UP.TotalUpvotes, 0) AS Upvotes,
        COALESCE(DOWN.TotalDownvotes, 0) AS Downvotes,
        PH.ClosedCount,
        PH.ReopenedCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ClosedCount,
            SUM(PostHistoryTypeId = 11) AS ReopenedCount 
        FROM 
            RecursivePostHistory
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN UserScores UP ON P.OwnerUserId = UP.UserId
    LEFT JOIN UserScores DOWN ON P.OwnerUserId = DOWN.UserId
)
SELECT    
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.Upvotes,
    PS.Downvotes,
    PS.ClosedCount,
    PS.ReopenedCount,
    U.Reputation AS UserReputation,
    CASE 
        WHEN PS.ClosedCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    PostStats PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id
WHERE 
    PS.Score > 0 
    AND U.Reputation > 1000
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC 
LIMIT 100;
