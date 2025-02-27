WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostRanking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.UserId AS ClosingUserId,
        ph.CreationDate AS ClosedDate,
        r.Comment
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Post Closed
    LEFT JOIN 
        Comments r ON r.PostId = p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalBounties,
    us.TotalCommentScore,
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.ViewCount,
    pr.PostRank,
    cp.ClosedPostId,
    cp.ClosingUserId,
    cp.ClosedDate,
    COALESCE(cp.Comment, 'No reason given') AS ClosureComment
FROM 
    UserStats us
LEFT JOIN 
    PostRanking pr ON us.UserId = pr.PostId
LEFT JOIN 
    ClosedPosts cp ON pr.PostId = cp.ClosedPostId
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.TotalPosts DESC, us.Reputation DESC, pr.ViewCount DESC;
