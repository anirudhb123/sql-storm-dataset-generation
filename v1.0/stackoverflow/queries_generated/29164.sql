WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(PostsTags.TagCount, 0) AS TagCount,
        COALESCE(CommentsCount.CommentNum, 0) AS CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RN
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TagCount
        FROM (
            SELECT 
                PostId,
                unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
            FROM Posts
            WHERE PostTypeId = 1
        ) AS TagsTable
        GROUP BY PostId
    ) PostsTags ON PostsTags.PostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentNum
        FROM Comments
        GROUP BY PostId
    ) AS CommentsCount ON CommentsCount.PostId = p.Id
    WHERE p.PostTypeId = 1 -- Only considering Questions
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.TagCount,
    rp.CommentCount,
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    rp.CreationDate
FROM RankedPosts rp
JOIN UserReputation u ON rp.OwnerUserId = u.UserId
WHERE rp.RN <= 5 -- Get top 5 viewed posts per user
ORDER BY rp.ViewCount DESC;
