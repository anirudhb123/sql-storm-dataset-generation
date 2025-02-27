WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class = 1, 0)::int) AS GoldBadges,
        SUM(COALESCE(b.Class = 2, 0)::int) AS SilverBadges,
        SUM(COALESCE(b.Class = 3, 0)::int) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(CASE WHEN UpVotes + DownVotes > 0 THEN UpVotes::float / (UpVotes + DownVotes) ELSE NULL END) AS AvgVoteRatio
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only include close and reopen events
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalViews,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CommentCount,
    pp.Score,
    pp.UpVotes,
    pp.DownVotes,
    cr.CloseReasons AS ClosedReasons
FROM 
    UserMetrics up
LEFT JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId AND pp.RowNum = 1  -- Get the latest post for each user
LEFT JOIN 
    ClosedPostReasons cr ON pp.PostId = cr.PostId
WHERE 
    up.TotalPosts > 5  -- Users with more than 5 posts
ORDER BY 
    up.TotalViews DESC, pp.Score DESC NULLS LAST
LIMIT 
    10;

This query performs the following:

1. The **RankedPosts** CTE selects details of posts with required metrics including ranking posts by creation date for each user.
  
2. The **UserMetrics** CTE aggregates user data, calculating total views, badge counts, total posts, and vote ratios.

3. The **ClosedPostReasons** CTE compiles a list of close reasons for posts that have been closed or reopened using string aggregation of close reason types.

4. The final query joins the user metrics, ranked latest posts, and closed post reasons, applying filters and sorting to showcase users with more than 5 posts, ordered by their view count and score.

Each segment demonstrates SQL features like outer joins, window functions, CTEs, aggregates, string expressions, and the handling of NULL values and corner cases such as vote ratios where total votes might be zero.
