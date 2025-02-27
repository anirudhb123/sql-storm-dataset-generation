WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, pt.Name
),
AnswerStats AS (
    SELECT 
        pa.ParentId AS QuestionId,
        COUNT(pa.Id) AS AnswerCount,
        AVG(pa.Score) AS AverageScore
    FROM 
        Posts pa
    WHERE 
        pa.PostTypeId = 2
    GROUP BY 
        pa.ParentId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rs.AnswerCount,
        rs.AverageScore,
        cb.UserId,
        cb.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AnswerStats rs ON rp.PostId = rs.QuestionId
    LEFT JOIN 
        UserBadges cb ON rp.OwnerUserId = cb.UserId
)
SELECT 
    cs.Title,
    cs.Score,
    cs.ViewCount,
    cs.AnswerCount,
    cs.AverageScore,
    u.DisplayName,
    (CASE 
        WHEN cs.BadgeCount IS NULL THEN 'No Badges'
        ELSE CONCAT(cs.BadgeCount, ' Badges')
    END) AS BadgeInfo,
    (SELECT STRING_AGG(pt.Name, ', ') 
     FROM PostHistory ph 
     JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
     WHERE ph.PostId = cs.PostId
     GROUP BY ph.PostId) AS PostHistoryDetails,
    (SELECT COUNT(*) 
     FROM ClosedPosts cp
     WHERE cp.PostId = cs.PostId AND cp.LastClosedDate > NOW() - INTERVAL '1 month') AS RecentlyClosed
FROM 
    CombinedStats cs 
JOIN 
    Users u ON cs.UserId = u.Id
WHERE 
    cs.ViewCount > 1000
AND 
    cs.Score > 0
AND 
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = cs.PostId AND v.VoteTypeId = 2) > 5
ORDER BY 
    cs.Score DESC, cs.ViewCount DESC
LIMIT 100;
