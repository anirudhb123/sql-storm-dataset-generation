WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        SUM(B.Class) AS TotalBadgeClass,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation >= (SELECT AVG(Reputation) FROM Users) -- Users above average reputation
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT PH.Id) AS HistoryCount,
        SUM(P.ViewCount) OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS CumulativeViews
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2020-01-01' -- Focus on recent posts
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        UB.DisplayName,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.HistoryCount,
        PS.CumulativeViews,
        CASE 
            WHEN PS.CumulativeViews IS NULL THEN 'No Views' 
            ELSE CAST(PS.CumulativeViews AS VARCHAR) 
        END AS ViewStatus
    FROM 
        UserBadges UB
    INNER JOIN 
        PostStats PS ON UB.UserId = PS.OwnerUserId
    WHERE 
        (UB.GoldBadges > 0 OR UB.SilverBadges > 0 OR UB.BronzeBadges > 0) -- Users with any badge
)
SELECT 
    DS.DisplayName,
    DS.GoldBadges,
    DS.SilverBadges,
    DS.BronzeBadges,
    DS.CommentCount,
    DS.UpVotes,
    DS.DownVotes,
    DS.HistoryCount,
    DS.CumulativeViews,
    DS.ViewStatus,
    CASE 
        WHEN DS.CommentCount = 0 THEN 'No Comments'
        WHEN DS.CommentCount > 10 THEN 'Active User'
        ELSE 'Lurker'
    END AS UserActivityStatus
FROM 
    CombinedStats DS
ORDER BY 
    DS.UpVotes DESC,
    DS.GoldBadges DESC,
    DS.CumulativeViews DESC
LIMIT 100;

This SQL query involves a series of common table expressions (CTEs) to gather statistics about users and their posts. It filters and aggregates data while utilizing advanced SQL features such as window functions, conditional logic, and outer joins to provide insight into user activity and reputation through badge and post metrics.
