WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.Reputation,
    up.PostCount,
    up.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.PostId -- This join should align UserStats to the ranked posts they have authored
WHERE 
    rp.Rank <= 5 -- Get top 5 posts for each user based on score
ORDER BY 
    up.Reputation DESC, rp.Score DESC;
