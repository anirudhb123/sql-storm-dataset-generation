WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(v.UserId IS NOT NULL)::int, 0) AS TotalVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.UserId,
    up.TotalBounties,
    up.TotalVotes,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId 
WHERE 
    up.TotalVotes > 0 AND 
    (up.TotalBounties > 0 OR up.GoldBadges > 0)
ORDER BY 
    up.TotalVotes DESC, 
    rp.Score DESC 
LIMIT 10;

-- Select all posts made by users who have received at least one vote in the last month
SELECT 
    p.Id, 
    p.Title, 
    p.Score, 
    v.CreationDate AS VoteDate,
    v.VoteTypeId
FROM 
    Posts p
JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    v.CreationDate >= NOW() - INTERVAL '1 month'
ORDER BY 
    p.Score DESC;

-- Using UNION ALL to combine results from two different queries
SELECT 
    p.Id AS PostId,
    'Post' AS PostType,
    p.Title AS PostTitle
FROM 
    Posts p
WHERE 
    p.ClosedDate IS NOT NULL

UNION ALL

SELECT 
    c.PostId, 
    'Comment' AS PostType, 
    c.Text AS PostTitle
FROM 
    Comments c
WHERE 
    c.CreationDate >= NOW() - INTERVAL '1 month';
