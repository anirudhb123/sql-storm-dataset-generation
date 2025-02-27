WITH RankedPostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ps.RevisionGUID,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        CASE 
            WHEN p.Score IS NULL THEN 'No Score'
            WHEN p.Score < 0 THEN 'Negative Score'
            WHEN p.Score > 100 THEN 'High Score'
            ELSE 'Moderate Score'
        END AS ScoreCategory
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ps ON ps.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    INNER JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) >= (SELECT AVG(SUM(p1.Score)) FROM Posts p1 GROUP BY p1.OwnerUserId) -- Users above average score
),

ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        COALESCE(ph.Comment, 'No Reason Given') AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10 -- Posts that are closed
    WHERE 
        COALESCE(ph.Comment, '') != ''
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)

SELECT 
    u.DisplayName,
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.ScoreCategory,
    t.TotalScore AS UserTotalScore,
    c.ClosedPostId,
    c.CloseReason,
    b.BadgeCount
FROM 
    RankedPostScores r
JOIN 
    TopUsers t ON r.PostId = (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = t.UserId 
        ORDER BY 
            p.Score DESC LIMIT 1
    )
LEFT JOIN 
    ClosedPosts c ON c.ClosedPostId = r.PostId
LEFT JOIN 
    UserBadges b ON b.UserId = t.UserId
ORDER BY 
    r.Score DESC, UserTotalScore DESC
LIMIT 100;

This SQL query combines various constructs including CTEs (Common Table Expressions), window functions, correlated subqueries, and joins. It ranks posts by score and view count, filters users above the average score, collects details on closed posts, and counts user badges, ultimately presenting a comprehensive view of user performance in the Stack Overflow schema.
