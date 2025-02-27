WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    ur.Reputation,
    ur.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserReputation ur ON up.Id = ur.UserId
WHERE 
    rp.RN = 1
    AND (rp.CommentCount > 5 OR rp.UpVoteCount - rp.DownVoteCount > 10)
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
