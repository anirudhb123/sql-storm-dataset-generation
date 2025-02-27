WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalBadges,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.RankByViews,
    CASE 
        WHEN up.Reputation > 1000 THEN 'Expert' 
        WHEN up.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice' 
    END AS UserLevel,
    CASE 
        WHEN rp.TotalComments IS NULL THEN 'No comments yet'
        ELSE CONCAT(rp.TotalComments, ' comment(s)') 
    END AS CommentStatus
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    rp.RankByViews <= 3
ORDER BY 
    up.Reputation DESC, 
    rp.ViewCount DESC
LIMIT 50;

SELECT 
    DISTINCT p.Id,
    p.Title,
    COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN ph.Comment IS NOT NULL THEN ph.Comment 
        ELSE 'No history comments' 
    END AS HistoryComment
FROM 
    Posts p
LEFT JOIN (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
                   SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM Votes 
    GROUP BY PostId
) v ON p.Id = v.PostId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
    SELECT MAX(CreationDate) 
    FROM PostHistory 
    WHERE PostId = p.Id
)
WHERE 
    p.CreationDate >= NOW() - INTERVAL '90 days'
ORDER BY 
    NetVotes DESC, 
    p.ViewCount DESC
LIMIT 30;
