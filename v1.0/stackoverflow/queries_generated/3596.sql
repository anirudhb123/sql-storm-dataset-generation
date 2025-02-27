WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetailed AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId AS EditorId,
        u.DisplayName AS EditorName,
        ph.Text AS ChangeDetail,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
),
RecentPostHistory AS (
    SELECT 
        PostId,
        ARRAY_AGG(DISTINCT ChangeDetail ORDER BY ChangeRank) AS Changes
    FROM 
        PostHistoryDetailed
    WHERE 
        ChangeRank <= 5
    GROUP BY 
        PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalBounty,
    ph.PostId,
    ph.Changes,
    COALESCE(closed.ClosedCount, 0) AS ClosedPosts,
    COALESCE(opened.OpenedCount, 0) AS OpenedPosts
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentPostHistory ph ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.UserId
) closed ON ups.UserId = closed.UserId
LEFT JOIN (
    SELECT 
        ph.UserId,
        COUNT(*) AS OpenedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 11 -- Post Reopened
    GROUP BY 
        ph.UserId
) opened ON ups.UserId = opened.UserId
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.TotalBounty DESC, ups.DisplayName;
