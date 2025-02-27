WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting with Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.Score,
        rp.Level + 1
    FROM 
        Posts a
    JOIN 
        Posts q ON a.ParentId = q.Id
    JOIN 
        RecursivePosts rp ON q.Id = rp.Id
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(CASE WHEN p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) THEN 1 ELSE 0 END) AS QuestionsLastYear
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Joining only Questions
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Score,
        COUNT(cm.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Comments cm ON rp.Id = cm.PostId
    LEFT JOIN 
        Votes v ON rp.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty-related votes
    GROUP BY 
        rp.Id, rp.Title, rp.OwnerUserId, rp.CreationDate, rp.Score
)
SELECT 
    u.DisplayName,
    u.QuestionsAsked,
    u.PositiveScoredQuestions,
    u.QuestionsLastYear,
    ub.BadgeNames,
    ps.PostId,
    ps.Title,
    ps.CreationDate AS PostCreationDate,
    ps.Score AS PostScore,
    ps.CommentCount,
    ps.TotalBounty,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ps.CreationDate DESC) AS PostRank
FROM 
    UserPerformance u
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
LEFT JOIN 
    PostStats ps ON u.UserId = ps.OwnerUserId
WHERE 
    u.QuestionsLastYear > 0 -- Only considering users who asked questions in the last year
    AND (ub.TotalBadges IS NULL OR ub.TotalBadges > 0) -- Ensure user has badges or is null
ORDER BY 
    u.QuestionsAsked DESC, 
    ps.Score DESC, 
    ps.CommentCount DESC;
