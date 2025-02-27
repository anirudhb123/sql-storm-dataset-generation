
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := @row_number + 1 AS ReputationRank
    FROM 
        Users u,
        (SELECT @row_number := 0) AS rn
    WHERE 
        u.Reputation > 100
    ORDER BY 
        u.Reputation DESC
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostDetails AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalScore,
        (SELECT AVG(v.BountyAmount) 
         FROM Votes v 
         WHERE v.UserId = ur.UserId AND v.BountyAmount IS NOT NULL) AS AvgBounty
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        MAX(ph.CreationDate) AS LatestEditDate,
        GROUP_CONCAT(DISTINCT pht.Name SEPARATOR ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.UserId, ph.PostId
)
SELECT 
    upd.UserId,
    upd.DisplayName,
    upd.Reputation,
    upd.TotalPosts,
    upd.TotalQuestions,
    upd.TotalAnswers,
    upd.TotalScore,
    upd.AvgBounty,
    phs.LatestEditDate,
    phs.EditTypes
FROM 
    UserPostDetails upd
LEFT JOIN 
    PostHistorySummary phs ON upd.UserId = phs.UserId
WHERE 
    upd.TotalPosts > 5 AND (upd.TotalAnswers IS NULL OR upd.TotalAnswers > 0)
ORDER BY 
    upd.Reputation DESC, 
    phs.LatestEditDate DESC 
LIMIT 10;
