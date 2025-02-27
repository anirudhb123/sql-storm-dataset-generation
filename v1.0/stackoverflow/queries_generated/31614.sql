WITH RecursivePostCounts AS (
    -- Recursive Common Table Expression to count the number of comments for each post
    SELECT 
        P.Id AS PostId, 
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    GROUP BY 
        P.Id
),
CTEUserBadges AS (
    -- CTE to find the number of badges for each user along with their reputation
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.Reputation
),
MaxPostViewCount AS (
    -- CTE to find the maximum view count for posts
    SELECT 
        MAX(ViewCount) AS MaxViews 
    FROM 
        Posts
),
FilteredPosts AS (
    -- Filter posts based on their view count and join them with the recursive post counts and user badges
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        RPC.CommentCount,
        CUB.UserId,
        CUB.Reputation,
        CUB.BadgeCount
    FROM 
        Posts P
    JOIN 
        RecursivePostCounts RPC ON RPC.PostId = P.Id
    JOIN 
        CTEUserBadges CUB ON CUB.UserId = P.OwnerUserId
    WHERE 
        P.ViewCount > (SELECT MaxViews FROM MaxPostViewCount) * 0.5
),

FinalResults AS (
    -- Final selection of filtered posts with additional computations
    SELECT 
        FP.PostId,
        FP.Title,
        FP.ViewCount,
        FP.CommentCount,
        FP.UserId,
        FP.Reputation,
        FP.BadgeCount,
        CASE 
            WHEN FP.Reputation >= 1000 THEN 'High Reputation'
            WHEN FP.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory,
        CASE 
            WHEN FP.BadgeCount > 5 THEN 'Experienced User'
            ELSE 'Novice User'
        END AS UserStatus
    FROM 
        FilteredPosts FP
)

SELECT 
    F.PostId,
    F.Title,
    F.ViewCount,
    F.CommentCount,
    F.Reputation,
    F.ReputationCategory,
    F.UserStatus
FROM 
    FinalResults F
WHERE 
    F.CommentCount > 10 -- Only get posts with more than 10 comments
ORDER BY 
    F.ViewCount DESC; -- Sort by view count in descending order
