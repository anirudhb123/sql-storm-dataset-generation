WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AvgAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers only
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostCount AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rb.BadgeCount, 0) AS BadgeCount,
    COALESCE(cpc.ClosedCount, 0) AS ClosedPostCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score AS QuestionScore,
    asst.AnswerCount,
    asst.AvgAnswerScore
FROM 
    Users u
LEFT JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    ClosedPostCount cpc ON u.Id = cpc.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    AnswerStats asst ON rp.PostId = asst.PostId
WHERE 
    (u.Reputation > 100 AND COALESCE(cpc.ClosedCount, 0) = 0) -- Users with high reputation and have not closed any posts
ORDER BY 
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
