WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) as Comment_Count,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) as Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) as Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, b.Class
),
UserActivity AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) as TotalViews,
        SUM(COALESCE(p.UpVotes, 0) - COALESCE(p.DownVotes, 0)) as OverallScore,
        COUNT(DISTINCT p.Id) as TotalPosts,
        MAX(p.LastActivityDate) as LastActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    ua.TotalViews,
    ua.OverallScore,
    ua.TotalPosts,
    ua.LastActive,
    rp.Title,
    rp.Comment_Count,
    rp.Upvotes,
    rp.Downvotes,
    rp.Rank,
    rp.BadgeClass
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
WHERE 
    rp.Rank <= 3
ORDER BY 
    ua.OverallScore DESC, rp.CreationDate DESC
LIMIT 50;
