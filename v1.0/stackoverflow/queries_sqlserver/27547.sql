
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(VoteTypeId) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(VoteTypeId) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS Downvotes,
        COALESCE((SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId), 0) AS BadgeCount,
        STRING_AGG(REPLACE(REPLACE(p.Tags, '><', ','), ' ', ''), ', ') AS FormattedTags
    FROM Posts p
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 YEAR' 
    GROUP BY p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
Statistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(Upvotes) AS TotalUpvotes,
        SUM(Downvotes) AS TotalDownvotes,
        AVG(BadgeCount) AS AverageBadges,
        STRING_AGG(DISTINCT FormattedTags, ', ') AS UniqueTags
    FROM PostStats
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.Upvotes,
        ps.Downvotes,
        (ps.Upvotes - ps.Downvotes) AS NetVotes,
        RANK() OVER (ORDER BY (ps.Upvotes - ps.Downvotes) DESC) AS VoteRank
    FROM PostStats ps
)
SELECT 
    s.TotalPosts,
    s.TotalComments,
    s.TotalUpvotes,
    s.TotalDownvotes,
    s.AverageBadges,
    s.UniqueTags,
    tp.Title AS TopPostTitle,
    tp.CommentCount AS TopPostComments,
    tp.Upvotes AS TopPostUpvotes,
    tp.Downvotes AS TopPostDownvotes,
    tp.NetVotes AS TopPostNetVotes
FROM Statistics s
JOIN TopPosts tp ON tp.VoteRank = 1;
