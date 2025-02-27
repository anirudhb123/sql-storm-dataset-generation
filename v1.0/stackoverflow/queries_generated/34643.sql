WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    UNION ALL
    SELECT 
        r.PostId,
        r.Title,
        r.UserId,
        r.CreationDate,
        r.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY r.PostId ORDER BY r.CreationDate DESC)
    FROM 
        RecursivePostHistory r
    JOIN 
        PostHistory ph ON r.PostId = ph.PostId
    WHERE 
        r.rn < 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (6, 10) THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (7, 20) THEN 1 END) AS ReopenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pp.PostId,
    pp.Title,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ups.UpVotes,
    ups.DownVotes,
    ups.CloseVotes,
    ups.ReopenVotes,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
FROM 
    RecursivePostHistory pp
JOIN 
    Users ur ON pp.UserId = ur.Id
JOIN 
    PostVoteStats ups ON pp.PostId = ups.PostId
LEFT JOIN 
    Comments c ON pp.PostId = c.PostId
LEFT JOIN 
    PostLinks pl ON pp.PostId = pl.PostId
WHERE 
    pp.PostHistoryTypeId IN (1, 2, 4, 6) -- Filter by post history types of interest
AND 
    ur.Reputation > 1000
GROUP BY 
    pp.PostId, pp.Title, ur.UserId, ur.Reputation, ur.BadgeCount, ups.UpVotes, ups.DownVotes, ups.CloseVotes, ups.ReopenVotes
HAVING 
    COUNT(DISTINCT c.Id) > 5 -- Only include posts with more than 5 comments
ORDER BY 
    ups.UpVotes DESC, pp.Title ASC;

