WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Relevant edits
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS ClosedReason,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN cr.Name END) AS ReopenReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalBounty,
    ppd.PostId,
    ppd.Title,
    ppd.RecentEdit,
    cpr.ClosedReason,
    cpr.ReopenReason
FROM 
    UserPostStats ups
JOIN 
    PostHistoryDetails ppd ON ups.UserId = ppd.UserId
LEFT JOIN 
    ClosedPostReasons cpr ON ppd.PostId = cpr.PostId
WHERE 
    ppd.RecentEdit = 1
ORDER BY 
    ups.TotalPosts DESC, ppd.Title;
