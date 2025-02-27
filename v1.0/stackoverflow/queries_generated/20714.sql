WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsWithStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswer,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND P.Score > 0
),
ClosedPosts AS (
    SELECT 
        Ph.PostId,
        Pt.Name AS HistoryType,
        COUNT(Ph.Id) AS CloseCount
    FROM 
        PostHistory Ph
    JOIN 
        PostHistoryTypes Pt ON Ph.PostHistoryTypeId = Pt.Id
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        Ph.PostId, Pt.Name
),
PostScores AS (
    SELECT 
        P.Id AS PostId,
        CASE 
            WHEN C.CloseCount IS NOT NULL THEN 
                P.Score - (C.CloseCount * 5) -- Penalty for each close vote
            ELSE 
                P.Score 
        END AS AdjustedScore
    FROM 
        Posts P
    LEFT JOIN 
        ClosedPosts C ON P.Id = C.PostId
),
FinalPostStats AS (
    SELECT
        PWS.PostId,
        PWS.Title,
        PWS.CreationDate,
        PWS.AcceptedAnswer,
        PWS.Score,
        PS.AdjustedScore,
        PS.CommentCount,
        UB.BadgeCount,
        UB.BadgeNames
    FROM 
        PostsWithStats PWS
    JOIN 
        PostScores PS ON PWS.PostId = PS.PostId
    JOIN 
        UserBadges UB ON PWS.OwnerUserId = UB.UserId
)
SELECT 
    FPS.PostId,
    FPS.Title,
    FPS.CreationDate,
    (CASE 
        WHEN FPS.CommentCount > 10 THEN 'Hot Post'
        ELSE 'Regular Post' 
    END) AS PostType,
    FPS.AdjustedScore,
    FPS.BadgeCount,
    FPS.BadgeNames,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = FPS.PostId AND V.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = FPS.PostId AND V.VoteTypeId = 3) AS Downvotes
FROM 
    FinalPostStats FPS
ORDER BY 
    FPS.AdjustedScore DESC
LIMIT 100;

