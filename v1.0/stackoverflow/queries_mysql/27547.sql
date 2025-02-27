
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
        GROUP_CONCAT(DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) ORDER BY numbers.n SEPARATOR ', ') AS FormattedTags
    FROM Posts p
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
Statistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(Upvotes) AS TotalUpvotes,
        SUM(Downvotes) AS TotalDownvotes,
        AVG(BadgeCount) AS AverageBadges,
        GROUP_CONCAT(DISTINCT FormattedTags) AS UniqueTags
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
        @rank := IF(@prev = (ps.Upvotes - ps.Downvotes), @rank, @rank + 1) AS VoteRank,
        @prev := (ps.Upvotes - ps.Downvotes)
    FROM PostStats ps, (SELECT @rank := 0, @prev := NULL) r
    ORDER BY (ps.Upvotes - ps.Downvotes) DESC
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
