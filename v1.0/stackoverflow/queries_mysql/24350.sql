
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AcceptedAnswerId,
        (@row_number:= IF(@prev_user = p.OwnerUserId, @row_number + 1, 1)) AS UserPostRank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(vs.VoteScore, 0)) AS TotalScore, 
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        GROUP_CONCAT(DISTINCT b.Name) AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            Vote.UserId,
            COUNT(CASE WHEN Vote.VoteTypeId = 2 THEN 1 END) AS VoteScore
        FROM 
            Votes Vote
        GROUP BY 
            Vote.UserId
    ) vs ON u.Id = vs.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        us.BadgeCount,
        us.Badges,
        (@rank:= @rank + 1) AS Ranking
    FROM 
        UserStats us,
        (SELECT @rank := 0) AS r
    WHERE 
        us.TotalPosts > 0
    ORDER BY 
        us.TotalScore DESC, us.BadgeCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    u.DisplayName,
    u.TotalPosts AS UserPostCount,
    u.TotalScore AS UserScore,
    u.BadgeCount AS UserBadgeCount,
    u.Badges AS UserBadges,
    COALESCE(NULLIF(rp.AcceptedAnswerId, -1), 0) AS EffectiveAcceptedAnswerId,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId 
            AND ph.PostHistoryTypeId IN (10, 11)
        ) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RecentPosts rp
JOIN 
    TopUsers u ON rp.OwnerUserId = u.UserId
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
