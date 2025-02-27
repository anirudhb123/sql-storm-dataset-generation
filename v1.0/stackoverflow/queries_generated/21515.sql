WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        SUM(CASE WHEN B.TagBased = 1 THEN 1 ELSE 0 END) AS TagBasedBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CloseReasons AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        CR.Name AS CloseReason,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.UserId, PH.PostId, CR.Name
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PS.TotalPosts,
    PS.Questions,
    PS.Answers,
    PS.TotalScore,
    PS.TotalViews,
    COALESCE(CR.CloseCount, 0) AS CloseCounts,
    COALESCE(CR.CloseReason, 'No close reasons') AS MostCommonCloseReason
FROM 
    UserBadges UB
JOIN 
    PostStats PS ON UB.UserId = PS.OwnerUserId
LEFT JOIN 
    CloseReasons CR ON UB.UserId = CR.UserId
WHERE 
    PS.TotalPosts > 5 
    AND (UB.GoldBadges > 0 OR UB.SilverBadges > 0 OR UB.BronzeBadges > 0)
ORDER BY 
    PS.TotalScore DESC, 
    PS.TotalViews DESC
LIMIT 10;

-- To capture peculiar cases where certain posts have never been closed despite low scores
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Score,
    COALESCE(CR.CloseCount, 0) AS CloseCount
FROM 
    Posts P
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
LEFT JOIN 
    CloseReasons CR ON P.Id = CR.PostId
WHERE 
    P.Score < 0 
    AND P.ViewCount < 100 
    AND P.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY 
    P.CreationDate DESC;
