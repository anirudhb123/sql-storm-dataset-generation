WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.LastActivityDate,
        P.OwnerUserId,
        P.ParentId,
        1 AS HierarchyLevel,
        ARRAY[P.Id] AS Path
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only for Questions

    UNION ALL
    
    SELECT 
        P2.Id,
        P2.Title,
        P2.Body,
        P2.CreationDate,
        P2.LastActivityDate,
        P2.OwnerUserId,
        P2.ParentId,
        RPC.HierarchyLevel + 1,
        RPC.Path || P2.Id
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostCTE RPC ON RPC.PostId = P2.ParentId
    WHERE 
        P2.PostTypeId = 2 -- Only for Answers
),
UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        RPC.PostId,
        RPC.Title,
        RPC.LastActivityDate,
        UBC.UserId,
        UBC.DisplayName,
        UBC.BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY RPC.PostId ORDER BY RPC.LastActivityDate DESC) AS ActivityRank
    FROM 
        RecursivePostCTE RPC
    INNER JOIN 
        UserBadgeCounts UBC ON RPC.OwnerUserId = UBC.UserId
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.LastActivityDate,
    PA.DisplayName AS OwnerDisplayName,
    PA.BadgeCount,
    CASE 
        WHEN PA.BadgeCount > 0 THEN 'Active User'
        ELSE 'New User'
    END AS UserStatus,
    COALESCE(PA2.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
    COALESCE(p.CreationDate, 'No Creation Date') AS PostCreationDate,
    CASE 
        WHEN PA.LastActivityDate IS NOT NULL THEN DATE_PART('day', CURRENT_TIMESTAMP - PA.LastActivityDate) 
        ELSE NULL 
    END AS DaysSinceLastActivity
FROM 
    PostActivity PA
LEFT JOIN 
    Posts p ON PA.PostId = p.AcceptedAnswerId
LEFT JOIN 
    Posts PA2 ON PA.PostId = PA2.ParentId AND PA2.PostTypeId = 2
WHERE 
    PA.ActivityRank = 1
    AND (PA.LastActivityDate IS NULL OR PA.LastActivityDate > CURRENT_DATE - INTERVAL '30 days')
ORDER BY 
    PA.BadgeCount DESC NULLS LAST,
    PA.PostId;
