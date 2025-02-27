
WITH RecursiveBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount,
        MAX(Date) AS LastBadgeDate
    FROM 
        Badges
    WHERE 
        Date >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY 
        UserId
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
), 
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATEADD(day, -30, CAST('2024-10-01 12:34:56' AS DATETIME))
), 
HighlightedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalViews,
        UA.QuestionsAsked,
        UA.TotalUpvotes,
        UA.TotalDownvotes,
        BC.BadgeCount,
        BC.LastBadgeDate
    FROM 
        UserActivity UA
    LEFT JOIN 
        RecursiveBadgeCounts BC ON UA.UserId = BC.UserId
    WHERE 
        UA.TotalViews >= 100 AND 
        (UA.QuestionsAsked > 5 OR UA.TotalUpvotes > 10)
)
SELECT 
    HU.UserId,
    HU.DisplayName,
    HU.TotalViews,
    HU.QuestionsAsked,
    HU.TotalUpvotes,
    HU.TotalDownvotes,
    HU.BadgeCount,
    HU.LastBadgeDate,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate
FROM 
    HighlightedUsers HU
LEFT JOIN 
    RecentPosts RP ON HU.UserId = RP.OwnerUserId AND RP.PostRank = 1
WHERE 
    HU.BadgeCount IS NULL OR 
    HU.LastBadgeDate < DATEADD(month, -6, CAST('2024-10-01 12:34:56' AS DATETIME))
ORDER BY 
    HU.TotalViews DESC,
    HU.TotalUpvotes DESC;
