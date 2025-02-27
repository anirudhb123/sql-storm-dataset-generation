WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.ParentId,
        COALESCE(p AcceptedAnswerId, -1) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        SUM(p.Score) > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.CommentCount, 0) AS CommentCount,
        COALESCE(cs.CloseCount, 0) AS CloseCount,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostStats ps ON u.Id = ps.AcceptedAnswer
    LEFT JOIN 
        ClosedPosts cs ON ps.PostId = cs.PostId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    up.TotalPosts,
    up.CommentCount,
    up.CloseCount,
    up.TotalScore,
    CASE 
        WHEN up.TotalScore IS NULL THEN 'No Score'
        WHEN up.TotalScore > 100 THEN 'High Scorer'
        ELSE 'Moderate Scorer'
    END AS ScoreCategory,
    (SELECT COUNT(*) FROM Tags) AS TotalTags,
    (SELECT COUNT(*) FROM Posts WHERE PostTypeId = 1) AS TotalQuestions,
    (SELECT COUNT(*) FROM Posts WHERE PostTypeId = 2) AS TotalAnswers
FROM 
    UserPostStats up
INNER JOIN 
    TopUsers u ON up.UserId = u.UserId
WHERE 
    up.CloseCount = 0
ORDER BY 
    up.TotalScore DESC
LIMIT 50;
