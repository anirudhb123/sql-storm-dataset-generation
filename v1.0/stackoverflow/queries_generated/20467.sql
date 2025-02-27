WITH RecursiveTagUsage AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
), FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation' 
            ELSE 'Low Reputation' 
        END AS ReputationCategory
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL AND u.CreationDate < CURRENT_DATE - INTERVAL '5 years'
), PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS InitialTitleDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 6 THEN ph.CreationDate END) AS LastEditedTagsDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN ph.Id END) AS CloseDeleteCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ru.PostId, 
    ru.TagsUsed, 
    ru.CommentCount,
    ru.TotalBounty,
    fu.DisplayName,
    fu.ReputationCategory,
    phs.InitialTitleDate,
    phs.LastEditedTagsDate,
    phs.CloseDeleteCount,
    phs.UniqueEditors
FROM 
    RecursiveTagUsage ru
JOIN 
    FilteredUsers fu ON ru.PostId IN (
        SELECT p.Id
        FROM Posts p
        WHERE p.OwnerUserId = fu.UserId
    ) 
JOIN 
    PostHistorySummary phs ON ru.PostId = phs.PostId
ORDER BY 
    ru.TotalBounty DESC,
    ru.CommentCount DESC,
    fu.Reputation DESC;
