WITH RecursiveUserHierarchy AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        0 AS Level
    FROM Users
    WHERE Id IN (SELECT DISTINCT OwnerUserId FROM Posts)
    
    UNION ALL 

    SELECT 
        U.Id, 
        U.Reputation, 
        Level + 1
    FROM Users U
    INNER JOIN Posts P ON P.OwnerUserId = U.Id
    INNER JOIN RecursiveUserHierarchy R ON P.OwnerUserId = R.UserId
), 

PostScoreBreakdown AS (
    SELECT
        P.Id AS PostId,
        P.Socre,
        CASE
            WHEN P.Score > 10 THEN 'High'
            WHEN P.Score BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),

OvertimeBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS Badges,
        MIN(B.Date) AS FirstBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Date >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        U.Id
),

FilteredPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Body,
        COALESCE(PH.UserDisplayName, P.OwnerDisplayName) AS DisplayName,
        PH.CreationDate AS LastHistoryDate,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '6 months')
)

SELECT 
    RH.UserId,
    RH.Reputation,
    PH.ScoreCategory,
    PH.UpVotes,
    PH.DownVotes,
    OB.BadgeCount,
    OB.Badges,
    FP.Title,
    FP.DisplayName,
    FP.LastHistoryDate,
    FP.PostStatus
FROM 
    RecursiveUserHierarchy RH
JOIN 
    PostScoreBreakdown PH ON RH.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PH.PostId)
JOIN 
    OvertimeBadges OB ON RH.UserId = OB.UserId
JOIN 
    FilteredPosts FP ON FP.Id = PH.PostId
WHERE 
    RH.Level < 3
ORDER BY 
    RH.Reputation DESC, 
    PH.ScoreCategory, 
    OB.BadgeCount DESC;
