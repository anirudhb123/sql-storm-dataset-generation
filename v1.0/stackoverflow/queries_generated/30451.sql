WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COALESCE(MAX(c.CreationDate), '2000-01-01'::timestamp) AS LatestCommentDate,
        COUNT(DISTINCT ppm.UserId) AS UniqueCommenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT 
             PostId, UserId 
         FROM 
             Comments) ppm ON ppm.PostId = p.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' -- Only consider posts created in the last year
    GROUP BY 
        p.Id
),
RankedPostDetails AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM 
        PostDetails pd
),
FinalResults AS (
    SELECT 
        rpd.Title,
        rpd.Score,
        rpd.ViewCount,
        rpd.LatestCommentDate,
        ubc.BadgeCount,
        rpd.PostRank
    FROM 
        RankedPostDetails rpd
    JOIN 
        UserBadgeCounts ubc ON rpd.PostId = (SELECT p.Id 
                                              FROM Posts p 
                                              WHERE p.OwnerUserId = ubc.UserId 
                                              ORDER BY p.Score DESC 
                                              LIMIT 1)
    WHERE 
        rpd.LatestCommentDate >= NOW() - INTERVAL '30 days' -- Only include posts with comments in the last month
)
SELECT 
    Title,
    Score,
    ViewCount,
    LatestCommentDate,
    BadgeCount,
    PostRank
FROM 
    FinalResults
ORDER BY 
    PostRank
FETCH FIRST 10 ROWS ONLY; -- Limit to top 10 posts
This SQL query includes several advanced constructs such as recursive CTEs, window functions, outer joins, and filtering based on both post attributes and corresponding user badge counts. The query aims to return the top 10 posts created in the last year that have received comments in the last month, ranked by score and view count, while also including the badge count for the post's owner.
