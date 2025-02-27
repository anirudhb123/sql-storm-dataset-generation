WITH RecursivePostHistory AS (
    SELECT 
        PH.Id,
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        PH.UserDisplayName,
        0 AS Depth
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Filtered for Close and Reopen events
    UNION ALL
    SELECT 
        PH.Id,
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        PH.UserDisplayName,
        Depth + 1
    FROM 
        PostHistory PH
    INNER JOIN 
        RecursivePostHistory RPH ON PH.PostId = RPH.PostId
    WHERE 
        RPH.Depth < 5
),
PostVoteCounts AS (
    SELECT
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        V.VoteTypeId IN (2, 3)  -- Count only Upvotes and Downvotes
    GROUP BY 
        P.Id
),
UserBadgeCounts AS (
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
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        PH.UserDisplayName AS CloseUser,
        PH.CreationDate AS CloseDate,
        COALESCE(VoteCounts.VoteCount, 0) AS VoteCount,
        COALESCE(BadgeCounts.BadgeCount, 0) AS UserBadgeCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EventOrder
    FROM 
        Posts P
    LEFT JOIN 
        RecursivePostHistory PH ON PH.PostId = P.Id
    LEFT JOIN 
        PostVoteCounts VoteCounts ON P.Id = VoteCounts.PostId
    LEFT JOIN 
        UserBadgeCounts BadgeCounts ON P.OwnerUserId = BadgeCounts.UserId
    WHERE 
        P.ClosedDate IS NOT NULL
)
SELECT 
    CP.PostId,
    CP.Title,
    CP.CreationDate,
    CP.ViewCount,
    CP.CloseUser,
    CP.CloseDate,
    CP.VoteCount,
    CP.UserBadgeCount,
    PH.UserDisplayName AS LastEditor,
    PH.LastEditDate
FROM 
    ClosedPosts CP
LEFT JOIN 
    Posts PH ON CP.PostId = PH.Id AND PH.LastEditDate IS NOT NULL
WHERE 
    CP.EventOrder = 1  -- Only get the latest close event per post
ORDER BY 
    CP.CloseDate DESC
LIMIT 100;  -- Limit to top 100 closed posts
