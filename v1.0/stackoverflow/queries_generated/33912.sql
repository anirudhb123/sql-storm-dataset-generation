WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS ActiveQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate > CURRENT_TIMESTAMP - INTERVAL '1 month'
    GROUP BY 
        u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.QuestionCount,
    us.TotalScore,
    us.BadgeCount,
    us.AvgViews,
    COALESCE(cp.CloseCount, 0) AS RecentCloseCount,
    COUNT(DISTINCT rp.PostId) AS TopQuestionsInRank,
    ARRAY_AGG(rp.Title) AS TopQuestionTitles
FROM 
    UserStats us
LEFT JOIN 
    ClosedPosts cp ON us.UserId = cp.PostId
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank <= 5
WHERE 
    us.QuestionCount > 0 -- Only users who have asked questions
GROUP BY 
    us.UserId, us.DisplayName, cp.CloseCount
ORDER BY 
    us.TotalScore DESC, us.QuestionCount DESC;
