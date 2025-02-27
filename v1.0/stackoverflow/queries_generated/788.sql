WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(MAX(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(MAX(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Badges WHERE UserId = u.Id) AS TotalBadges
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalBadges,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
        WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    rp.rn = 1
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 50;
