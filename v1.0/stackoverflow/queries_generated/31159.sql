WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
), UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        COALESCE(AVG(p.ViewCount), 0) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgViewCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ph.Comment 
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
      AND 
        ph.PostHistoryTypeId IN (10, 11) -- Only interested in close and reopen events
), PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AvgViewCount,
    r.PostId,
    r.Title AS RecentlyChangedPostTitle,
    r.CreationDate AS RecentChangeDate,
    COALESCE(pwv.Upvotes, 0) AS Upvotes,
    COALESCE(pwv.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN r.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT COUNT(*) FROM Posts WHERE Id = r.AcceptedAnswerId AND OwnerUserId = r.OwnerUserId)
        ELSE 0 
    END AS AcceptedAnswersCount,
    CASE 
        WHEN t.ScoreRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorType
FROM 
    TopUsers t
INNER JOIN 
    UserPostStats u ON t.UserId = u.UserId
LEFT JOIN 
    RecentPostHistory r ON u.UserId = r.OwnerUserId
LEFT JOIN 
    PostsWithVotes pwv ON r.PostId = pwv.PostId
WHERE 
    u.TotalPosts > 0
ORDER BY 
    u.TotalScore DESC, 
    r.CreationDate DESC;
