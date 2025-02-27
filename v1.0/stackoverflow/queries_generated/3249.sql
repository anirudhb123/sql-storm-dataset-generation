WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        v.PostId
), PostsWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(badges.BadgeCount, 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT 
            UserId,
            COUNT(*) AS BadgeCount
         FROM 
            Badges 
         GROUP BY 
            UserId) badges ON u.Id = badges.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rv.VoteCount,
    rv.UpVotes,
    rv.DownVotes,
    pb.TotalBadges,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot'
        WHEN rp.Score > 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostsWithBadges pb ON rp.PostId = pb.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC NULLS LAST, 
    rp.CreationDate DESC;
