WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.Tags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
),
PopularPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.OwnerDisplayName,
        pb.BadgeCount,
        pb.BadgeNames,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank
    FROM PostDetails pd
    JOIN UserBadges pb ON pd.OwnerDisplayName = pb.UserId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    pp.BadgeCount,
    pp.BadgeNames
FROM PopularPosts pp
WHERE pp.Rank <= 10
ORDER BY pp.Score DESC, pp.ViewCount DESC;

-- This query benchmarks string processing by combining user badge information with post details,
-- focusing on popular questions by score and view count. It also aggregates badge names into 
-- a single string for better readability and analysis.
