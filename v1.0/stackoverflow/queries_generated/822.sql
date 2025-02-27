WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AcceptedQuestions,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalAnswers DESC) AS UserRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
PostCommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
PostsWithStats AS (
    SELECT 
        p.*,
        pcs.CommentCount,
        pcs.LastCommentDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostOrder
    FROM 
        Posts p
    LEFT JOIN 
        PostCommentStats pcs ON p.Id = pcs.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.UserDisplayName AS ClosureUser,
        ph.CreationDate AS ClosureDate,
        CRT.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes CRT ON ph.Comment::int = CRT.Id
)

SELECT 
    tu.DisplayName AS UserName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AcceptedQuestions,
    pws.Id AS PostId,
    pws.Title,
    pws.CreationDate AS PostCreationDate,
    pws.CommentCount,
    pws.LastCommentDate,
    cp.CloseReason AS ClosureReason,
    cp.ClosureUser AS ClosedBy,
    cp.ClosureDate AS ClosedOn
FROM 
    TopUsers tu
LEFT JOIN 
    PostsWithStats pws ON tu.UserId = pws.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON pws.Id = cp.ClosedPostId
WHERE 
    (pws.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW() OR cp.CloseReason IS NOT NULL)
ORDER BY 
    tu.UserRank, pws.CreationDate DESC 
LIMIT 100;
