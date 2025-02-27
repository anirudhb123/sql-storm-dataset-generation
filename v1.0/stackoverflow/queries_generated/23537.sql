WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(c.Score), 0) AS CommentScore,
        COALESCE(SUM(b.Class), 0) AS BadgeScore,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentScore,
        ps.BadgeScore,
        RANK() OVER (ORDER BY (ps.CommentScore + ps.BadgeScore) DESC) AS PostRank
    FROM 
        PostStats ps
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS TotalPosts,
    SUM(COALESCE(rp.CommentScore, 0)) AS TotalCommentScore,
    SUM(COALESCE(rp.BadgeScore, 0)) AS TotalBadgeScore,
    AVG(COALESCE(rp.CommentScore, 0)) AS AverageCommentScore,
    AVG(COALESCE(rp.BadgeScore, 0)) AS AverageBadgeScore,
    (SELECT COUNT(*) FROM RankedPosts rp WHERE rp.PostRank <= 10) AS TopTenPostsCount
FROM 
    UserVotes u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
GROUP BY 
    u.UserId, u.DisplayName
HAVING 
    SUM(COALESCE(rp.CommentScore, 0)) > 0
ORDER BY 
    TotalPosts DESC, AverageCommentScore DESC
LIMIT 20;

-- Notes: 
-- This query generates a comprehensive report of user activity and post statistics,
-- incorporating several advanced SQL features like CTEs, window functions, 
-- LEFT JOINs to handle NULLs for users without votes or posts, and complex
-- HAVING conditions for filtering results. 
