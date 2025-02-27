WITH UserBadges AS (
    SELECT DISTINCT u.Id AS UserId, u.DisplayName, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularTags AS (
    SELECT DISTINCT t.TagName, t.Count AS TagCount
    FROM Tags t
    WHERE t.Count > 100
),
HighScorePosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount
    FROM Posts p
    WHERE p.Score > 50 AND p.ViewCount > 500
),
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.Body, u.DisplayName AS OwnerName, hp.CreationDate AS PostCreated, hp2.CreationDate AS LastEdited
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory hp ON p.Id = hp.PostId AND hp.PostHistoryTypeId = 1
    LEFT JOIN PostHistory hp2 ON p.Id = hp2.PostId AND hp2.PostHistoryTypeId = 5
),
RecentActivity AS (
    SELECT p.Id AS PostId, COUNT(c.Id) AS CommentCount, MAX(v.VoteTypeId) AS HighestVoteType
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
)
SELECT 
    p.Title AS PostTitle, 
    p.Body AS PostBody, 
    d.OwnerName,
    ub.BadgeCount,
    pt.TagName AS PopularTag,
    p.Score AS PostScore,
    r.CommentCount,
    r.HighestVoteType,
    d.PostCreated AS PostCreated, 
    d.LastEdited AS LastEdited 
FROM 
    PostDetails d
JOIN 
    HighScorePosts p ON d.PostId = p.Id
JOIN 
    UserBadges ub ON d.OwnerName = ub.DisplayName
JOIN 
    PopularTags pt ON pt.TagCount > 50
JOIN 
    RecentActivity r ON d.PostId = r.PostId
ORDER BY 
    p.Score DESC, p.ViewCount DESC, ub.BadgeCount DESC
LIMIT 100;
