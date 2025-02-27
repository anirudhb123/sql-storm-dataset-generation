
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId,
        DENSE_RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank,
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ur.DisplayName,
        ur.Reputation,
        rp.CreationDate,
        rp.PostRank,
        rp.TotalComments
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.PostRank = 1 AND ur.Reputation > 100
)
SELECT 
    hsp.Title,
    COUNT(DISTINCT ph.PostId) AS RelatedPostCount,
    GROUP_CONCAT(DISTINCT ph.Comment SEPARATOR '; ') AS CloseReasons,
    hsp.Reputation * hsp.TotalComments AS EngagementScore
FROM HighScorePosts hsp
LEFT JOIN PostHistory ph ON hsp.PostId = ph.PostId
WHERE ph.PostHistoryTypeId IN (10, 11) 
GROUP BY hsp.Title, hsp.Reputation, hsp.TotalComments
ORDER BY EngagementScore DESC
LIMIT 10;
