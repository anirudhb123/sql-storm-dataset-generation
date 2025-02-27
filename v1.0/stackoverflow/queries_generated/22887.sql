WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= '2023-01-01' -- Questions created in 2023
),
LatestAnswers AS (
    SELECT 
        a.Id AS AnswerId,
        a.Score AS AnswerScore,
        a.ParentId AS QuestionId,
        p.Title AS QuestionTitle
    FROM 
        Posts a
    JOIN 
        Posts p ON a.ParentId = p.Id
    WHERE 
        a.PostTypeId = 2 -- Only Answers
        AND a.CreationDate = (SELECT MAX(CreationDate) FROM Posts WHERE ParentId = a.ParentId)
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate,
        crt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Name
),
PostScoreAnalysis AS (
    SELECT 
        p.Id AS PostId,
        (COALESCE(p.Score, 0) + COALESCE(a.AnswerCount, 0)) AS TotalScore,
        (p.ViewCount * COALESCE(b.BadgeCount, 1)) AS AdjustedViews
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        UserBadges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
)
SELECT 
    rp.Title AS LatestQuestionTitle,
    rp.CreationDate AS LatestQuestionDate,
    la.AnswerId,
    la.QuestionTitle,
    la.AnswerScore,
    CASE 
        WHEN cr.PostId IS NOT NULL THEN cr.CloseReason 
        ELSE 'Open'
    END AS QuestionStatus,
    psa.TotalScore AS QuestionScore,
    psa.AdjustedViews
FROM 
    RankedPosts rp
LEFT JOIN 
    LatestAnswers la ON rp.PostId = la.QuestionId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    PostScoreAnalysis psa ON rp.PostId = psa.PostId
WHERE
    rp.rn = 1 -- Only the latest question per user
ORDER BY 
    rp.CreationDate DESC,
    la.AnswerScore DESC;
