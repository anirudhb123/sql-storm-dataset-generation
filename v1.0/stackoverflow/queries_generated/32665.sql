WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId, 
        pl.RelatedPostId,
        1 AS Depth
    FROM 
        PostLinks pl
    UNION ALL
    SELECT 
        pl.PostId, 
        pl.RelatedPostId,
        rpl.Depth + 1
    FROM 
        PostLinks pl
    JOIN 
        RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosureDate,
        ph.UserDisplayName AS ClosedBy,
        DATEDIFF(DAY, p.CreationDate, ph.CreationDate) AS DaysOpen
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostViewCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT COALESCE(c.UserId, -1)) AS UniqueViewers
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalBounty,
    ups.TotalUpvotes,
    ups.TotalDownvotes,
    pp.PostId,
    pp.ClosureDate,
    pp.ClosedBy,
    pp.DaysOpen,
    pvc.UniqueViewers,
    COALESCE(rpl.RelatedPostId, -1) AS LinkedPostId,
    rpl.Depth
FROM 
    UserPostStats ups
LEFT JOIN 
    ClosedPostStats pp ON ups.TotalQuestions > 0
LEFT JOIN 
    PostViewCounts pvc ON ups.TotalQuestions > 0
LEFT JOIN 
    RecursivePostLinks rpl ON ups.TotalQuestions > 0
WHERE 
    (ups.TotalUpvotes - ups.TotalDownvotes) > 10
ORDER BY 
    ups.TotalScore DESC, 
    up.DisplayName;

