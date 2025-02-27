WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS comment_count,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName,
        SUM(p.ViewCount) AS total_views,
        COUNT(DISTINCT p.Id) AS total_posts,
        SUM(b.Class = 1) AS gold_badges,
        SUM(b.Class = 2) AS silver_badges,
        SUM(b.Class = 3) AS bronze_badges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS history_count,
        MAX(ph.CreationDate) AS last_modified
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id,
    p.Title,
    p.Score,
    p.ViewCount,
    up.created AS user_created,
    usr.total_views,
    usr.total_posts,
    usr.gold_badges,
    usr.silver_badges,
    usr.bronze_badges,
    phc.history_count,
    phc.last_modified
FROM 
    RankedPosts p
JOIN 
    UserStats usr ON p.OwnerUserId = usr.user_id
LEFT JOIN 
    PostHistoryCount phc ON p.Id = phc.PostId
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
WHERE 
    p.rank = 1
    AND (usr.total_views > 1000 OR phc.history_count > 5)
ORDER BY 
    p.Score DESC, p.CreatedDate DESC;
