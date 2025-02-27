WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.PostTypeId,
        P.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Starting with Questions
    
    UNION ALL
    
    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.CreationDate,
        P2.PostTypeId,
        P2.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        Posts P1 ON P2.ParentId = P1.Id
    WHERE 
        P2.PostTypeId = 2  -- And including its Answers
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        MAX(CreationDate) AS LastVoteDate
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostStatistics AS (
    SELECT 
        PH.PostId,
        PH.Title,
        PH.OwnerUserId,
        COALESCE(RV.VoteCount, 0) AS VoteCount,
        RV.LastVoteDate,
        COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(UB.GoldBadges, 0) AS UserGoldBadges,
        COALESCE(UB.SilverBadges, 0) AS UserSilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS UserBronzeBadges,
        AVG(P.Score) OVER (PARTITION BY PH.OwnerUserId) AS AvgScoreOfOwner,
        COUNT(C.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(RV.LastVoteDate, '1900-01-01') DESC) AS RankByRecentVotes
    FROM 
        RecursivePostHierarchy PH
    LEFT JOIN 
        RecentVotes RV ON PH.PostId = RV.PostId
    LEFT JOIN 
        UserBadges UB ON PH.OwnerUserId = UB.UserId
    LEFT JOIN 
        Comments C ON PH.PostId = C.PostId
    GROUP BY 
        PH.PostId, PH.Title, PH.OwnerUserId, RV.VoteCount, RV.LastVoteDate, UB.BadgeCount,
        UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
)
SELECT 
    PS.PostId,
    PS.Title,
    U.DisplayName AS OwnerDisplayName,
    PS.VoteCount,
    PS.UserBadgeCount,
    PS.UserGoldBadges,
    PS.UserSilverBadges,
    PS.UserBronzeBadges,
    PS.AvgScoreOfOwner,
    PS.CommentCount,
    PS.RankByRecentVotes,
    DENSE_RANK() OVER (ORDER BY PS.VoteCount DESC) AS RankByVotes
FROM 
    PostStatistics PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id
WHERE 
    (PS.VoteCount > 10 OR PS.UserBadgeCount > 0)  -- Filter for popular posts with badges
    AND PS.CommentCount > 5  -- Must have comments
ORDER BY 
    PS.RankByVotes, PS.RankByRecentVotes
OPTION (RECOMPILE);
