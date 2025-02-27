WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        C.Name AS CloseReason,
        PH.CreationDate AS CloseDate
    FROM 
        PostHistory PH
        JOIN CloseReasonTypes C ON PH.PostHistoryTypeId = 10 AND PH.Comment::int = C.Id -- Roles for close reasons
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.AnswerCount,
        RP.CommentCount,
        COALESCE(CR.CloseReason, 'N/A') AS CloseReason,
        CR.CloseDate,
        UR.Reputation AS UserReputation,
        UR.BadgeCount,
        UR.GoldBadges,
        UR.SilverBadges,
        UR.BronzeBadges
    FROM 
        RankedPosts RP
        LEFT JOIN CloseReasons CR ON RP.PostId = CR.PostId
        LEFT JOIN Users U ON RP.PostId = U.Id
        LEFT JOIN UserReputation UR ON U.Id = UR.UserId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.CloseReason,
    PS.CloseDate,
    PS.UserReputation,
    PS.BadgeCount,
    PS.GoldBadges,
    PS.SilverBadges,
    PS.BronzeBadges
FROM 
    PostStatistics PS
WHERE 
    PS.Rank <= 5 -- Top 5 posts by type
ORDER BY 
    PS.PostId DESC; -- Order by PostId for display

-- Additionally, show average reputation of users based on badge classification
SELECT 
    AVG(UserReputation) AS AvgUserReputation,
    COUNT(UserId) AS UserCount
FROM 
    UserReputation
WHERE 
    BadgeCount > 0;
