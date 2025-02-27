WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        0 AS Level
    FROM Users
    WHERE AccountId IS NULL  -- Starting point for root users

    UNION ALL

    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.AccountId = uh.Id
), 

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 8), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostNumber
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId 
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEditDate,
        ph.UserId,
        ht.Name AS EditType
    FROM PostHistory ph
    JOIN PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE ht.Name IN ('Edit Title', 'Edit Body')
    GROUP BY ph.PostId, ph.UserId, ht.Name
),

UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)

SELECT
    uh.DisplayName AS UserDisplayName,
    uh.Reputation AS UserReputation,
    pd.Title AS PostTitle,
    pd.ViewCount AS PostViewCount,
    pd.CommentCount AS PostCommentCount,
    pd.Score AS PostScore,
    ph.LastEditDate,
    ub.BadgeCount,
    ub.BadgeNames,
    CASE 
        WHEN pd.TotalBounty > 0 THEN 'Yes'
        ELSE 'No'
    END AS HasBountyAwarded
FROM UserHierarchy uh
JOIN PostDetails pd ON uh.Id = pd.OwnerUserId
LEFT JOIN PostHistoryDetails ph ON pd.PostId = ph.PostId
LEFT JOIN UserBadges ub ON uh.Id = ub.UserId
WHERE 
    uh.Reputation > 1000
    AND pd.PostNumber <= 5 
    AND pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    uh.Reputation DESC, 
    pd.ViewCount DESC;
