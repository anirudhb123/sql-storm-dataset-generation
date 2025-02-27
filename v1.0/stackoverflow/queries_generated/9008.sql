WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
UserStatistics AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredQuestions
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        UserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)
SELECT 
    up.DisplayName AS UserName,
    us.TotalPosts,
    us.PositiveScorePosts,
    us.NegativeScorePosts,
    us.AnsweredQuestions,
    rb.BadgeNames,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    UserStatistics us
JOIN 
    Users up ON us.UserId = up.Id
LEFT JOIN 
    RecentBadges rb ON us.UserId = rb.UserId
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
ORDER BY 
    us.TotalPosts DESC, rp.ViewCount DESC;
