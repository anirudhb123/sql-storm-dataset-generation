WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        TotalScore > 0
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    coalesce(rp.Title, 'No recent posts') AS RecentPostTitle,
    coalesce(rp.CreationDate::date, 'N/A') AS RecentPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerUserId AND rp.RecentRank = 1
WHERE 
    tu.ScoreRank <= 10
ORDER BY 
    tu.ScoreRank;

-- Additional Queries
SELECT 
    ph.PostId,
    p.Title,
    ph.CreationDate,
    p.OwnerDisplayName,
    p.Body,
    pt.Name AS PostTypeName,
    STRING_AGG(DISTINCT ct.Name, ', ') AS CloseReasons
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    CloseReasonTypes ct ON ph.Comment::int = ct.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    ph.CreationDate >= NOW() - INTERVAL '1 month'
    AND pht.Name IN ('Post Closed', 'Post Reopened')
GROUP BY 
    ph.PostId, p.Title, ph.CreationDate, p.OwnerDisplayName, p.Body, pt.Name
ORDER BY 
    ph.CreationDate DESC;
