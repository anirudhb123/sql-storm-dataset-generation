WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    WHERE 
        u.Reputation > 1000  -- Filter for users with reputation greater than 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalBounties,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalReputation DESC) AS PostRank
    FROM 
        UserStats
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM 
        Posts p
    JOIN 
        string_to_array(p.Tags, ',') AS Tag ON true
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM Tag)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.QuestionCount,
    QS.AvgScore,
    QS.MaxViews,
    QS.TagsUsed,
    COALESCE(u.TotalBounties, 0) AS TotalBounties
FROM 
    TopUsers u
LEFT JOIN 
    QuestionStats QS ON u.UserId = QS.OwnerUserId
WHERE 
    u.PostRank <= 10 -- Top 10 users by post count
ORDER BY 
    u.PostRank;

-- Query to get distinct posts with history and their most recent edit details
SELECT 
    p.Id AS PostId,
    p.Title,
    h.PostHistoryTypeId,
    h.UserDisplayName AS EditedBy,
    h.CreationDate AS EditDate,
    COALESCE(h.Comment, 'No comment') AS EditComment
FROM 
    Posts p
LEFT JOIN 
    PostHistory h ON p.Id = h.PostId
WHERE 
    h.CreationDate = (SELECT MAX(CreationDate) 
                      FROM PostHistory 
                      WHERE PostId = p.Id)
ORDER BY 
    p.Id;

-- Outer query to get posts with limited views and not edited
SELECT 
    p.Id,
    p.Title,
    p.ViewCount,
    CASE 
        WHEN p.ViewCount < 100 THEN 'Low'
        WHEN p.ViewCount BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS ViewLevel
FROM 
    Posts p
WHERE 
    p.LastEditDate IS NULL
    OR p.CreationDate > CURRENT_DATE - INTERVAL '90 days'
    AND p.ViewCount IS NOT NULL
ORDER BY 
    ViewLevel DESC, p.ViewCount;
