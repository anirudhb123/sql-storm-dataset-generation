WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT ph.Id) AS TotalPostHistory,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
CommentsStats AS (
    SELECT
        c.UserId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBounty,
    us.TotalQuestions,
    us.TotalPostHistory,
    us.AvgViewCount,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    COALESCE(cs.LastCommentDate, 'No comments yet') AS LastCommentDate,
    rp.Title AS LatestQuestionTitle
FROM 
    UserStatistics us
LEFT JOIN 
    CommentsStats cs ON us.UserId = cs.UserId
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    us.TotalQuestions > 5
ORDER BY 
    us.TotalBounty DESC,
    us.TotalQuestions DESC,
    us.AvgViewCount DESC;
