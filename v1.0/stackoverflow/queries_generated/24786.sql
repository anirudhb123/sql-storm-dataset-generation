WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        (COALESCE(SUM(COMMENT_COUNT), 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS COMMENT_COUNT 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON v.PostId = c.PostId
    GROUP BY 
        u.Id
),
PostsWithClosedStatus AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ClosedDate IS NOT NULL AS IsClosed,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open' 
        END AS Status
    FROM 
        Posts p
),
AggregatedPostStats AS (
    SELECT 
        pp.UserId,
        SUM(pp.Score) AS TotalScore,
        COUNT(DISTINCT pp.PostId) AS TotalPosts,
        COUNT(DISTINCT pp.IsClosed) AS TotalClosedPosts
    FROM 
        PostsWithClosedStatus pp
    GROUP BY 
        pp.UserId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.UpvotesReceived,
    us.DownvotesReceived,
    aps.TotalScore,
    aps.TotalPosts,
    aps.TotalClosedPosts,
    COALESCE(rp.PostId, 'No Posts') AS BestPostId,
    COALESCE(rp.Title, 'N/A') AS BestPostTitle,
    COALESCE(rp.Score, 0) AS BestPostScore,
    COALESCE(rp.ViewCount, 0) AS BestPostViewCount
FROM 
    UserStatistics us
LEFT JOIN 
    AggregatedPostStats aps ON us.UserId = aps.UserId
LEFT JOIN 
    RankedPosts rp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    us.Reputation > 100
ORDER BY 
    us.Reputation DESC, us.BadgeCount DESC, aps.TotalScore DESC;
