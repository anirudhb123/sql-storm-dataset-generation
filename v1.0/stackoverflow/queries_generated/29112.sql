WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        ps.*,
        CASE
            WHEN UpvoteCount > DownvoteCount THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        PostStatistics ps
    WHERE 
        CommentCount > 5
        AND PostRank <= 10
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.GoldBadges,
    ps.SilverBadges,
    ps.BronzeBadges,
    ps.Popularity
FROM 
    FilteredPosts ps
ORDER BY 
    ps.UpvoteCount DESC, ps.CommentCount DESC;
