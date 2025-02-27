WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserID,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId AS EditorUserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS CloseDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 -- Closed
    LEFT JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS int) -- Assuming Comment contains the CloseReasonId
    GROUP BY 
        p.Id, ph.CreationDate
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate AS QuestionDate,
    u.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    COALESCE(clp.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(clp.CloseReasons, 'No Close Reasons') AS CloseReasons,
    CASE 
        WHEN rp.RankPerUser = 1 THEN 'Top Question'
        ELSE 'Other Questions'
    END AS QuestionRank,
    COUNT(DISTINCT cp.Id) AS RelatedClosedCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON ub.UserID = u.Id
LEFT JOIN 
    ClosedPosts clp ON clp.Id = rp.PostID
LEFT JOIN 
    PostLinks pl ON rp.PostID = pl.PostId
LEFT JOIN 
    Posts cp ON pl.RelatedPostId = cp.Id AND cp.PostTypeId = 1 AND clp.CloseDate IS NOT NULL 
WHERE 
    rp.RankPerUser <= 5 -- Considering top 5 questions for each user
GROUP BY 
    rp.PostID, rp.Title, rp.CreationDate, u.DisplayName, ub.BadgeCount, clp.CloseDate, clp.CloseReasons, rp.RankPerUser
ORDER BY 
    rp.CreationDate DESC;
