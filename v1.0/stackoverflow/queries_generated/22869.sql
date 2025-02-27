WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 
        END) AS QuestionCount,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 
        END) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.CreationDate) AS MedianPostCreationDate
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
HighScoringPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p 
    WHERE 
        p.Score > (
            SELECT AVG(Score) 
            FROM Posts 
            WHERE PostTypeId = 1
        )
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  -- focusing on close/open/delete events
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalViews,
    ups.TotalScore,
    hsp.Title AS HighScoringPostTitle,
    hsp.Score AS HighScoringPostScore,
    phd.CreationDate AS LastStatusChangeDate,
    phd.Comment AS LastStatusChangeComment,
    phd.UserDisplayName AS LastUpdatedBy
FROM 
    UserPostStats ups
LEFT JOIN 
    HighScoringPosts hsp ON ups.UserId = hsp.OwnerUserId AND hsp.ScoreRank = 1
LEFT JOIN 
    PostHistoryDetails phd ON ups.UserId = (
        SELECT OwnerUserId FROM Posts p WHERE p.Id = phd.PostId
    )
WHERE 
    ups.PostCount > 5 
ORDER BY 
    ups.TotalScore DESC, 
    ups.UserId;

-- Bonus: To stress-test, let's add a query that works with NULL logic
WITH EffectiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(MAX(posts.AnswerCount), 0) AS MaxAnswers,
        SUM(v.BountyAmount) AS TotalBounties,
        CASE 
            WHEN COUNT(posts.Id) > 0 THEN 'Active' 
            ELSE 'Inactive' 
        END AS UserStatus
    FROM 
        Users u
    LEFT JOIN 
        Posts posts ON u.Id = posts.OwnerUserId
    LEFT JOIN 
        Votes v ON posts.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    UserId,
    MaxAnswers,
    TotalBounties,
    UserStatus
FROM 
    EffectiveUsers
WHERE 
    (UserStatus IS NULL OR UserStatus = 'Inactive')
    AND MaxAnswers < 3
ORDER BY 
    TotalBounties DESC, 
    UserId;

