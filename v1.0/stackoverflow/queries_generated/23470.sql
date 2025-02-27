WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
ClosedPostHistories AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Close actions
    LEFT JOIN 
        CloseReasonTypes c ON ph.Comment::INT = c.Id
    GROUP BY 
        p.Id
), 
FinalPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        ub.BadgeCount,
        ub.BadgeNames,
        cph.LastClosedDate,
        cph.CloseCount,
        cph.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        ClosedPostHistories cph ON rp.PostId = cph.PostId
)
SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.Score,
    fps.CommentCount,
    COALESCE(fps.BadgeCount, 0) AS BadgeCount,
    COALESCE(fps.BadgeNames, 'None') AS BadgeNames,
    COALESCE(fps.LastClosedDate, 'Never') AS LastClosedDate,
    COALESCE(fps.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN fps.CloseCount > 5 THEN 'Frequently Closed'
        WHEN fps.CloseCount BETWEEN 1 AND 5 THEN 'Occasionally Closed'
        ELSE 'Not Closed'
    END AS ClosureStatus
FROM 
    FinalPostStats fps
WHERE 
    fps.UserRank = 1  -- Selecting the top-ranked post for each user
ORDER BY 
    fps.Score DESC, fps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;  -- Paginate the results
