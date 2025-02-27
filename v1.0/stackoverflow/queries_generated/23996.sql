WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        CASE 
            WHEN p.ParentId IS NOT NULL THEN 'Answered'
            WHEN EXISTS (SELECT 1 FROM Posts p2 WHERE p2.AcceptedAnswerId = p.Id) THEN 'Accepted'
            ELSE 'Unanswered' 
        END AS AnswerStatus
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year' -- Last year
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(ctr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen history
    GROUP BY 
        ph.PostId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    up.Reputation,
    rb.GoldBadges,
    rb.SilverBadges,
    rb.BronzeBadges,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    COALESCE(cp.CloseReasons, ARRAY[]::varchar[]) AS CloseReasons,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) FILTER (WHERE rp.Rank <= 5) AS AvgTop5Views,
    COUNT(DISTINCT rp.AcceptedAnswerId) AS AcceptedAnswers
FROM 
    Users up
LEFT JOIN 
    UserBadges rb ON up.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    PostCloseReasons cp ON rp.Id = cp.PostId
GROUP BY 
    up.Id, rb.GoldBadges, rb.SilverBadges, rb.BronzeBadges
HAVING 
    COUNT(DISTINCT rp.Id) >= 10 -- Users with a minimum of 10 questions
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 20;
