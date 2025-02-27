WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(ub.BadgeCount, 0) AS BadgeCount, 
        ur.Reputation AS UserReputation
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    JOIN UserReputation ur ON u.Id = ur.UserId
    WHERE ur.PostCount > 5
    ORDER BY ur.Reputation DESC
    LIMIT 10
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id
),
HighScoringPosts AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.Score,
        pwc.CommentCount,
        pwc.LastCommentDate,
        tp.UserId
    FROM PostWithComments pwc
    JOIN RankedPosts rp ON pwc.PostId = rp.PostId
    JOIN Posts tp ON tp.Id = rp.PostId
    WHERE tp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
)

SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.UserReputation,
    hsp.Title AS HighScoringPostTitle,
    hsp.Score AS PostScore,
    hsp.CommentCount AS NumberOfComments,
    COALESCE(JSON_AGG(DISTINCT c.Text), '[]') AS Comments,
    EXTRACT(EPOCH FROM (hsp.LastCommentDate - hsp.LastCommentDate)) AS SecondsSinceLastComment,
    CASE 
        WHEN hsp.CommentCount IS NULL THEN 'No comments yet'
        ELSE CONCAT(hsp.CommentCount, ' comments')
    END AS CommentStatus
FROM HighScoringPosts hsp
JOIN TopUsers tu ON tu.UserId = hsp.UserId
LEFT JOIN Comments c ON hsp.PostId = c.PostId
GROUP BY 
    tu.DisplayName, 
    tu.BadgeCount, 
    tu.UserReputation, 
    hsp.Title, 
    hsp.Score, 
    hsp.CommentCount, 
    hsp.LastCommentDate
ORDER BY 
    tu.UserReputation DESC,
    hsp.Score DESC;
