WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    ) t ON true
    WHERE p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, u.Reputation
),
PostHistoryWithMaxReputation AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.CreationDate,
        r.OwnerDisplayName,
        r.Reputation,
        r.CommentCount,
        r.VoteCount,
        r.Tags,
        MAX(b.Class) AS HighestBadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM RankedPosts r
    LEFT JOIN Badges b ON r.OwnerDisplayName = b.UserId
    GROUP BY r.PostId, r.Title, r.Body, r.CreationDate, r.OwnerDisplayName, r.Reputation, r.CommentCount, r.VoteCount, r.Tags
),
FilteredPosts AS (
    SELECT 
        p.*,
        CASE 
            WHEN p.Reputation >= 1000 THEN 'Expert'
            WHEN p.Reputation >= 500 THEN 'Intermediate'
            ELSE 'Newcomer'
        END AS UserLevel
    FROM PostHistoryWithMaxReputation p
    WHERE p.VoteCount > 10 OR p.CommentCount > 5
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    OwnerDisplayName,
    Reputation,
    UserLevel,
    VoteCount,
    CommentCount,
    Tags,
    HighestBadgeClass,
    BadgeCount
FROM FilteredPosts
ORDER BY CreationDate DESC
LIMIT 100;
