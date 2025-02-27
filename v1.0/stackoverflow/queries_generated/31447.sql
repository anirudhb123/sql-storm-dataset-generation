WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= now() - INTERVAL '1 year' -- Posts created in the last year
),
RecentBadges AS (
    SELECT 
        B.UserId,
        B.Name AS BadgeName,
        B.Class,
        RANK() OVER (PARTITION BY B.UserId ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Badges B
    WHERE 
        B.Class IN (1, 2) -- Gold and Silver badges only
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName AS ClosedBy,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.CreationDate,
    R.OwnerReputation,
    RB.BadgeName,
    RB.Class AS BadgeClass,
    CP.ClosedBy,
    CP.CloseReason
FROM 
    RankedPosts R
LEFT JOIN 
    RecentBadges RB ON R.OwnerUserId = RB.UserId AND RB.BadgeRank = 1 -- Most recent badge
LEFT JOIN 
    ClosedPosts CP ON R.PostId = CP.PostId
WHERE 
    R.Rank <= 5 -- Top 5 posts per type
ORDER BY 
    R.PostId;

This SQL query does the following:
1. Creates a Common Table Expression (CTE) `RankedPosts` to rank posts by score and creation date within each post type, filtering for posts created within the last year.
2. Creates another CTE `RecentBadges` to fetch the most recent badges awarded to users, specifically focusing on Gold and Silver badges.
3. Creates a third CTE `ClosedPosts` to gather information on closed posts, including who closed them and the relevant close reason.
4. Joins these CTEs to compile a comprehensive result set, displaying the top 5 posts of each type along with the most recent badge of the owner (if available) and details about each post's closure (if applicable).
5. The results are ordered by PostId.
