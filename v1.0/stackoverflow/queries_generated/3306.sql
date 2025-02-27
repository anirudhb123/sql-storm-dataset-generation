WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        AVG(P.ViewCount) AS AverageViews,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS UpvoteRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount AS PostViews,
        COUNT(C) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount
), ClosedPosts AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT C.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalUpvotes,
    US.TotalDownvotes,
    US.GoldBadges + US.SilverBadges + US.BronzeBadges AS TotalBadges,
    US.AverageViews,
    PP.PostId,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.PostViews,
    COALESCE(CP.CloseReasons, 'No Closures') AS CloseReasons,
    COALESCE(CP.CloseCount, 0) AS TotalClosures
FROM 
    UserStats US
LEFT JOIN 
    PopularPosts PP ON US.UserId = P.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON PP.PostId = CP.PostId
WHERE 
    US.TotalUpvotes > US.TotalDownvotes
ORDER BY 
    US.TotalUpvotes DESC, US.UpvoteRank;
