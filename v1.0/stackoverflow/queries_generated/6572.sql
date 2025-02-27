WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Consider only Questions
),

MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(d.PostId) AS TotalPosts,
        SUM(d.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts d ON u.Id = d.OwnerUserId
    WHERE 
        d.CreationDate >= NOW() - INTERVAL '1 year' -- Consider only posts from the last year
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year' -- Badges received in the last year
    GROUP BY 
        b.UserId
)

SELECT 
    mu.DisplayName AS UserName,
    mu.TotalPosts,
    mu.TotalScore,
    COALESCE(ub.TotalBadges, 0) AS BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount
FROM 
    MostActiveUsers mu
LEFT JOIN 
    UserBadges ub ON mu.UserId = ub.UserId
JOIN 
    RankedPosts rp ON mu.UserId = rp.OwnerDisplayName
WHERE 
    rp.PostRank = 1 -- Get the latest post for each user
ORDER BY 
    mu.TotalPosts DESC, 
    rp.CreationDate DESC;
