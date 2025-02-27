WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
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
        QuestionCount,
        AnswerCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, QuestionCount DESC) AS UserRank
    FROM 
        UserPostStats
    WHERE 
        TotalScore > 0
)
SELECT 
    u.DisplayName AS TopUser,
    u.TotalScore,
    COALESCE(rp.PostId, -1) AS TopPostId,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, -1) AS HighestScore,
    CASE 
        WHEN u.LastPostDate IS NULL THEN 'No Activity' 
        WHEN u.LastPostDate < CURRENT_DATE - INTERVAL '30 days' THEN 'Inactive' 
        ELSE 'Active' 
    END AS ActivityStatus
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.OwnerPostRank = 1
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.TotalScore DESC;

-- Incorporating some bizarre corner cases
WITH CloseReasons AS (
    SELECT 
        ph.PostHistoryTypeId,
        cr.Name AS ReasonName,
        COUNT(*) AS ReasonCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY 
        ph.PostHistoryTypeId, cr.Name
    HAVING 
        COUNT(*) > 5
)
SELECT 
    r.ReasonName,
    r.ReasonCount,
    CASE 
        WHEN SUM(CASE WHEN r.ReasonCount > 10 THEN 1 ELSE 0 END) > 0 THEN 'Frequent Close Reason' 
        ELSE 'Occasional Close Reason'
    END AS ReasonFrequency
FROM 
    CloseReasons r
GROUP BY 
    r.ReasonName, r.ReasonCount
ORDER BY 
    r.ReasonCount DESC;

-- A peculiar selection combining multiple obscure cases
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(c.Text, 'No Comments') AS LastCommentText,
    c.CreationDate AS LastCommentDate,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    CASE 
        WHEN COUNT(DISTINCT v.Id) > 100 THEN 'Highly Engaged' 
        WHEN COUNT(DISTINCT c.Id) = 0 THEN 'Lonely Post'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
WHERE 
    p.ViewCount > 50 OR (p.Score IS NOT NULL AND p.Score >= 0)
GROUP BY 
    p.Id, p.Title, c.CreationDate
HAVING 
    (p.CreationDate < CURRENT_DATE - INTERVAL '1 year' AND COUNT(DISTINCT c.Id) < 5)
    OR (p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' AND SUM(v.VoteTypeId) IS NULL)
ORDER BY 
    EngagementLevel DESC, Total
