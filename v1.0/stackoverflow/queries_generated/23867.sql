WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn 
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
    AND 
        p.Score > (
            SELECT AVG(Score) FROM Posts WHERE PostTypeId IN (1, 2) 
        )
),
UserStatistics AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsPosted,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersPosted,
        AVG(p.Score) AS AvgScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        u.UserID,
        u.DisplayName, 
        u.Reputation,
        u.QuestionsPosted, 
        u.AnswersPosted, 
        u.AvgScore,
        RANK() OVER (ORDER BY u.AvgScore DESC) AS UserRank
    FROM 
        UserStatistics u
    WHERE 
        u.Reputation > 1000
)

SELECT 
    tp.UserID,
    tp.DisplayName,
    tp.Reputation,
    tp.QuestionsPosted,
    tp.AnswersPosted,
    tp.AvgScore,
    rp.Title AS MostRecentPost,
    rp.Score AS PostScore,
    CASE 
        WHEN tp.UserRank <= 10 THEN 'Top Contributor'
        WHEN tp.AvgScore IS NULL THEN 'No Score Yet'
        ELSE 'Contributor'
    END AS UserCategory
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.UserID = rp.OwnerUserId 
WHERE 
    rp.rn = 1   -- Join to get the most recent post
ORDER BY 
    tp.UserRank, tp.Reputation DESC;

-- Additional check for NULL logic in another select
SELECT 
    up.UserID,
    up.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN up.Reputation IS NULL OR up.Reputation < 1000 THEN 'Low Reputation' 
        ELSE 'High Reputation' 
    END AS ReputationStatus
FROM 
    UserStatistics up
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON up.UserID = b.UserId
WHERE 
    up.QuestionsPosted > 0
ORDER BY 
    ReputationStatus;
