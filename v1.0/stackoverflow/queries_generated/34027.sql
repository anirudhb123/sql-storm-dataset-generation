WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        0 AS Level,
        p.AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        r.Level + 1,
        p.AcceptedAnswerId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    up.DisplayName,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.TotalScore,
    rph.Title AS RecentPostTitle,
    COALESCE(c.CloseVoteCount, 0) AS CloseVotes,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT rp.Title, ', ') 
         FROM RecursivePostHierarchy rp 
         WHERE rp.AcceptedAnswerId = up.UserId), 
        'No Accepted Answers') AS RelatedAcceptedAnswers
FROM 
    UserPostStats up
LEFT JOIN 
    RecentPostEdits r ON up.UserId = r.UserId AND r.EditRank = 1 -- Latest edit
LEFT JOIN 
    ClosedPosts c ON r.PostId = c.PostId
WHERE 
    up.TotalPosts > 10
ORDER BY 
    up.TotalScore DESC;
