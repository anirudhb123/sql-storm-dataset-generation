WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(rp.UpVotes, 0) AS UpVotes,
    COALESCE(rp.DownVotes, 0) AS DownVotes,
    rp.Title,
    rp.ViewCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, rp.ViewCount DESC
LIMIT 10;

SELECT 
    pt.Name AS PostType, 
    COUNT(*) AS TotalPosts 
FROM 
    Posts p 
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id 
WHERE 
    p.CreationDate >= NOW() - INTERVAL '6 months' 
GROUP BY 
    pt.Name 
ORDER BY 
    TotalPosts DESC;

SELECT 
    'Voted Up' AS VoteType, 
    COUNT(*) AS TotalVotes 
FROM 
    Votes v 
WHERE 
    v.VoteTypeId = 2 
UNION ALL 
SELECT 
    'Voted Down', 
    COUNT(*) 
FROM 
    Votes v 
WHERE 
    v.VoteTypeId = 3;
