WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
), 
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ph.Level AS QuestionLevel,
        UPD.UserId AS LastEditorId,
        UPD.LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            UserId, 
            MAX(LastEditDate) AS LastEditDate
         FROM 
            Posts 
         WHERE 
            LastEditDate IS NOT NULL
         GROUP BY 
            PostId, UserId) UPD ON p.Id = UPD.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
AggregatedPostStats AS (
    SELECT
        ps.*,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        LAG(ps.ViewCount) OVER (ORDER BY ps.CreationDate) AS PrevViewCount,
        DATEDIFF(day, ps.CreationDate, GETDATE()) AS DaysActive
    FROM 
        PostStatistics ps
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.BadgeCount,
    a.GoldBadgeCount,
    a.SilverBadgeCount,
    a.BronzeBadgeCount,
    aps.Title,
    aps.CreationDate,
    aps.Score,
    aps.ViewCount,
    aps.UpVotes,
    aps.DownVotes,
    aps.DaysActive
FROM 
    UserWithBadges a
JOIN 
    AggregatedPostStats aps ON aps.LastEditorId = a.UserId
WHERE 
    a.Reputation > 1000 
    AND aps.DaysActive > 30 
    AND (aps.UpVotes - aps.DownVotes) > 10
ORDER BY 
    a.BadgeCount DESC, 
    aps.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
