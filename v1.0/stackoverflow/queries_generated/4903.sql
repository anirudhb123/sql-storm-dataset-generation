WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) as TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) as UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) as DownVotes,
        COALESCE(SUM(b.Class), 0) as TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) as CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 10
    GROUP BY 
        p.Id, p.Title, p.ViewCount
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.UpVotes,
    ua.DownVotes,
    ua.TotalBadges,
    rp.Title as TopPostTitle,
    rp.CreationDate as TopPostDate,
    pp.ViewCount as PopularPostViews,
    pp.CommentCount as PopularPostComments
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PopularPosts pp ON pp.CommentCount > 5
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.UpVotes DESC, ua.DownVotes ASC NULLS LAST;
