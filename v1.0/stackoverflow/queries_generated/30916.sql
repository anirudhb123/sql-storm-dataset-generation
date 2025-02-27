WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
QuestionTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, '><')) AS Tag
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
)
SELECT 
    qp.Title,
    qp.CreationDate,
    u.DisplayName AS Owner,
    ur.Reputation AS OwnerReputation,
    ur.BadgeCount,
    JSON_AGG(DISTINCT qt.Tag) AS Tags,
    ra.CommentCount,
    ra.VoteCount,
    COALESCE(NULLIF(qp.Score, 0), 'No Score') AS ActualScore,
    qp.ViewCount
FROM RankedPosts qp
JOIN Users u ON qp.OwnerUserId = u.Id
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN QuestionTags qt ON qp.Id = qt.PostId
LEFT JOIN RecentActivity ra ON qp.Id = ra.PostId
WHERE qp.PostRank <= 3 -- Get top 3 recent posts by each user
GROUP BY qp.Id, u.DisplayName, ur.Reputation, ur.BadgeCount, qp.Score, qp.ViewCount
ORDER BY qp.CreationDate DESC;
