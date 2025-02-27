WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS FirstClose,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClose
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CommentSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(CHAR_LENGTH(c.Text)) AS AvgCommentLength
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AcceptedAnswers,
    COUNT(DISTINCT p.PostId) AS TotalPostsLiked,
    SUM(COALESCE(ps.Depth, 0)) AS TotalHierarchyDepth,
    COALESCE(c.TotalComments, 0) AS TotalComments,
    COALESCE(c.AvgCommentLength, 0) AS AvgCommentLength
FROM 
    Users u
JOIN 
    UserPostStats ups ON u.Id = ups.UserId
LEFT JOIN 
    RecursivePostHierarchy ps ON ps.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id
    )
LEFT JOIN 
    PostHistoryAnalysis pha ON pha.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id
    )
LEFT JOIN 
    CommentSummary c ON c.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id
    )
GROUP BY 
    u.DisplayName, ups.TotalPosts, ups.Questions, ups.Answers, ups.AcceptedAnswers, c.TotalComments, c.AvgCommentLength
ORDER BY 
    TotalPosts DESC, TotalComments DESC;
