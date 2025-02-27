WITH RecursivePostPaths AS (
    -- CTE to get all posts and their parent post information
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL  -- Start with top-level posts
    UNION ALL
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        PP.Title,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostPaths PP ON P.ParentId = PP.PostId
),
UserBadges AS (
    -- Aggregate users' badge data
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVoteAggregates AS (
    -- Aggregate post votes to get upvote and downvote counts
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    P.Id AS PostId,
    P.Title,
    COALESCE(PA.UpVoteCount, 0) AS UpVotes,
    COALESCE(PA.DownVoteCount, 0) AS DownVotes,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    RPP.Level AS PostLevel
FROM 
    Posts P
LEFT JOIN 
    PostVoteAggregates PA ON P.Id = PA.PostId
JOIN 
    RecursivePostPaths RPP ON P.Id = RPP.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
ORDER BY 
    UpVotes DESC, 
    DownVotes ASC, 
    P.Title COLLATE "C" ASC;  -- Order by upvotes, then downvotes, and title
