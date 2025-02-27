WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pi.*,
        CASE 
            WHEN PostRank = 1 THEN 'Top Post'
            WHEN PostRank <= 5 THEN 'Top 5 Posts'
            ELSE 'Other Posts'
        END AS PostCategory
    FROM PostInfo pi
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.ClosedCount,
    rp.PostCategory
FROM RankedPosts rp
WHERE rp.PostRank <= 10 
  AND rp.ClosedCount = 0
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 15;

WITH RECURSIVE CommentTree AS (
    SELECT 
        c.Id,
        c.PostId,
        c.Text,
        c.UserDisplayName,
        ARRAY[c.Id] AS Path
    FROM Comments c
    WHERE c.PostId IN (SELECT PostId FROM RankedPosts WHERE PostRank <= 10)

    UNION ALL

    SELECT 
        c.Id,
        c.PostId,
        c.Text,
        c.UserDisplayName,
        ct.Path || c.Id
    FROM Comments c
    JOIN CommentTree ct ON ct.PostId = c.PostId AND c.Id <> ANY(ct.Path)
)
SELECT 
    ct.PostId,
    JSON_AGG(JSON_BUILD_OBJECT('commentId', ct.Id, 'text', ct.Text, 'userDisplayName', ct.UserDisplayName)) AS Comments
FROM CommentTree ct
GROUP BY ct.PostId
HAVING COUNT(ct.Id) >= 3;

SELECT DISTINCT 
    p.Title,
    t.TagName,
    COUNT(*) OVER (PARTITION BY t.TagName) AS TagUsageCount,
    CASE WHEN p.ClosedDate IS NOT NULL THEN 'Closed' ELSE 'Open' END AS Status
FROM Posts p
JOIN UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')) AS t(tag) ON TRUE
JOIN Tags t ON t.TagName = t.tag
WHERE t.Count > 10
ORDER BY TagUsageCount DESC
LIMIT 5;

SELECT 
    ph.PostId,
    COUNT(DISTINCT ph.UserId) AS UniqueEditors
FROM PostHistory ph
LEFT JOIN Posts p ON p.Id = ph.PostId 
WHERE ph.CreationDate >= NOW() - INTERVAL '6 months'
  AND ph.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY ph.PostId
HAVING COUNT(DISTINCT ph.UserId) > 1;

SELECT 
    u.DisplayName,
    SUM(b.Class = 1) AS GoldBadges,
    SUM(b.Class = 2) AS SilverBadges,
    SUM(b.Class = 3) AS BronzeBadges
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation > 500
GROUP BY u.DisplayName
HAVING COALESCE(SUM(b.Class), 0) > 0
ORDER BY SUM(b.Class = 1) DESC, SUM(b.Class = 2) DESC, SUM(b.Class = 3) DESC
LIMIT 10;
