WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        COALESCE(c.UserDisplayName, 'Community User') AS OwnerDisplayName,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1 -- Filtering only questions
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit operations
    GROUP BY 
        ph.PostId, ph.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rps.PostId,
    rps.Title,
    rps.CreationDate,
    rps.Score,
    rps.AnswerCount,
    rps.OwnerDisplayName,
    COALESCE(ph.LastEditDate, 'No Edits') AS LastEditDate,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    RecursivePostStats rps
LEFT JOIN 
    PostHistories ph ON rps.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON rps.OwnerUserId = ub.UserId
WHERE 
    rps.PostRank = 1 -- Only the latest post of each user
ORDER BY 
    rps.Score DESC
LIMIT 100;
