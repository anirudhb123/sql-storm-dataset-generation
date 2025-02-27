WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(u.LastAccessDate) AS LastActive
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        UpVotes,
        DownVotes,
        PostCount,
        BadgeCount,
        AvgScore,
        LastActive,
        RANK() OVER (ORDER BY Reputation DESC, UpVotes DESC) AS UserRank
    FROM UserStatistics
    WHERE Reputation > (SELECT AVG(Reputation) FROM Users)
),
UserPostDetails AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM TopUsers u
    JOIN Posts p ON u.UserId = p.OwnerUserId
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN (SELECT PostId, COUNT(*) AS EditCount FROM PostHistory GROUP BY PostId) ph ON p.Id = ph.PostId
)
SELECT 
    ud.DisplayName,
    ud.Title,
    ud.CreationDate,
    ud.Score,
    ud.CommentCount,
    ph.Comment AS LastEditComment,
    u.Reputation AS UserReputation,
    CASE 
        WHEN ud.EditCount = 0 THEN 'Never edited'
        WHEN ud.EditCount IS NULL THEN 'No edits available'
        ELSE CONCAT(ud.EditCount, ' edits made')
    END AS EditInfo,
    STRING_AGG(DISTINCT t.TagName, ', ' ORDER BY t.TagName) AS RelatedTags
FROM UserPostDetails ud
LEFT JOIN Tags t ON t.ExcerptPostId = ud.PostId
LEFT JOIN PostHistory ph ON ud.PostId = ph.PostId AND ph.PostHistoryTypeId = 4 -- Edited Title
JOIN Users u ON u.Id = ud.UserId
WHERE ud.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE PostTypeId = 1)
GROUP BY ud.DisplayName, ud.Title, ud.CreationDate, ud.Score, ud.CommentCount, ph.Comment, u.Reputation, ud.EditCount
HAVING ud.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
ORDER BY u.Reputation DESC, ud.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
