WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Start with Answers

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.Id = ph.ParentId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.CommentCount,
        ua.TotalBounties,
        ROW_NUMBER() OVER (ORDER BY ua.PostCount DESC, ua.CommentCount DESC) AS Rank
    FROM 
        UserActivity ua
),
ClosedPosts AS (
    SELECT 
        ph.Id,
        ph.Title,
        ph.ParentId,
        ph.Level,
        COUNT(p.Id) AS ChildAnswers
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Posts p ON p.ParentId = ph.Id
    WHERE 
        ph.Level = 1 -- Select only answers
    GROUP BY 
        ph.Id, ph.Title, ph.ParentId, ph.Level
),
PostWithCloseReasons AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ClosedDate,
        pr.Comment AS CloseReason
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    LEFT JOIN 
        CloseReasonTypes pr ON JSON_VALUE(ph.Comment, '$.CloseReasonId')::int = pr.Id -- Extracting the close reason ID
    WHERE 
        p.ClosedDate IS NOT NULL
)
SELECT 
    u.DisplayName AS TopUser,
    u.PostCount,
    u.CommentCount,
    u.TotalBounties,
    COALESCE(cp.ChildAnswers, 0) AS AnsweredPosts,
    p.CloseReason,
    p.Title AS ClosedPostTitle
FROM 
    TopUsers u
LEFT JOIN 
    ClosedPosts cp ON u.PostCount > 0 AND cp.ChildAnswers > 0
LEFT JOIN 
    PostWithCloseReasons p ON cp.Id = p.PostId
WHERE 
    u.Rank <= 10 -- Only top 10 users
ORDER BY 
    u.PostCount DESC;
