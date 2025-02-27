WITH RecursivePostStatistics AS (
    -- CTE to get the posts and calculate their vote scores
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(V.TotalVotes, 0) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (2, 3) -- Considering Only Upvotes and Downvotes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
),
UserBadges AS (
    -- CTE to get badges per user and aggregate counts
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopPosts AS (
    -- CTE to retrieve the top posts with the most votes by users who also have badges
    SELECT 
        RPS.PostId, 
        RPS.Title, 
        RPS.CreationDate, 
        RPS.TotalVotes,
        U.DisplayName,
        UB.BadgeCount
    FROM 
        RecursivePostStatistics RPS
    JOIN 
        Users U ON RPS.RN = 1 AND RPS.OwnerUserId = U.Id
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    WHERE 
        UB.BadgeCount > 0
    ORDER BY 
        RPS.TotalVotes DESC
    LIMIT 10
)
SELECT 
    TP.PostId, 
    TP.Title, 
    TP.CreationDate, 
    TP.TotalVotes, 
    TP.DisplayName,
    CASE 
        WHEN TP.BadgeCount > 0 THEN 'User has badges'
        ELSE 'No badges'
    END AS BadgeStatus
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId AND PH.PostHistoryTypeId = 10 -- History for closed posts
WHERE 
    PH.Id IS NULL -- Exclude any posts that have been closed
ORDER BY 
    TP.TotalVotes DESC;
