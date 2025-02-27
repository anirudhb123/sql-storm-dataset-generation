WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) OVER (PARTITION BY p.Id) AS UniqueVoterCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
),
PopularPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.CreationDate, 
        rp.OwnerUserId, 
        rp.CommentCount,
        rp.UniqueVoterCount
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
FinalReport AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges,
        pp.Title AS PopularPostTitle,
        pp.ViewCount AS PopularPostViewCount,
        pp.CommentCount AS PopularPostCommentCount,
        pp.UniqueVoterCount AS PopularPostUniqueVoterCount
    FROM 
        UserStats up
    LEFT JOIN 
        PopularPosts pp ON up.UserId = pp.OwnerUserId
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.PopularPostTitle IS NOT NULL THEN 'Has Popular Post' 
        ELSE 'No Popular Post' 
    END AS PostStatus, 
    COALESCE(NULLIF(fr.PopularPostCommentCount, 0), 'None') AS CommentCountDisplay,
    COALESCE(NULLIF(fr.PopularPostViewCount, 0), 'No Views') AS ViewCountDisplay
FROM 
    FinalReport fr
ORDER BY 
    fr.GoldBadges DESC, fr.TotalPosts DESC NULLS LAST;

This SQL query performs several intricate operations:

- It begins by identifying posts of type "Question" from the past year, ranking them based on view count, and calculating the total number of comments and unique voters for each post.
  
- The `PopularPosts` CTE retrieves the top questions (highest view count for each user) from the previous CTE.
  
- Another CTE, `UserStats`, aggregates user information including their badge counts and total number of posts.
  
- Finally, `FinalReport` combines user statistics with their most popular posts, implements conditional logic with `CASE` expressions to determine post status, and employs `COALESCE` with `NULLIF` to handle potential NULL values in a user-friendly manner.

- The result set is ordered by the number of gold badges and total posts, ensuring that users with greater recognition appear first, with NULL values handled at the end.
