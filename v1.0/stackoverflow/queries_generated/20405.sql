WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(vt.ReputationImpact), 0) AS TotalVoteImpact,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.HistoryCount,
        RANK() OVER (PARTITION BY pd.PostTypeId ORDER BY pd.CommentCount DESC, pd.HistoryCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    us.UserId,
    us.Reputation,
    us.TotalVoteImpact,
    us.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.HistoryCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRankStatus
FROM 
    UserStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    RankedPosts rp ON p.Id = rp.PostId
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND rp.CommentCount > 10 
    AND us.BadgeCount > 0
ORDER BY 
    us.Reputation DESC, rp.CommentCount DESC;

-- Including NULL logic
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
    COUNT(DISTINCT CASE 
        WHEN b.Id IS NOT NULL THEN b.Id 
        ELSE NULL
    END) AS ActiveBadges
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.LastAccessDate IS NOT NULL
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT v.Id) > 5
ORDER BY 
    Upvotes - Downvotes DESC
LIMIT 10;
