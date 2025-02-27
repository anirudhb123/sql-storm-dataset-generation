WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 5 -- Only high-scoring questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(ub.TotalBadges, 0) AS UserTotalBadges,
    COALESCE(ub.HighestBadgeClass, 0) AS UserHighestBadgeClass,
    cq.CloseReason,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedQuestions cq ON rp.PostId = cq.PostId
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId AND v.VoteTypeId IN (8, 9) -- Only BountyStart and BountyClose votes
WHERE 
    rp.PostRank = 1 -- Get only the latest question per user
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, ub.TotalBadges, ub.HighestBadgeClass, cq.CloseReason
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
