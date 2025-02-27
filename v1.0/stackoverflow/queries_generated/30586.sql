WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId, 
        Title, 
        ParentId, 
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Questions
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedPostData AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalMetrics AS (
    SELECT 
        p.Title,
        u.DisplayName,
        a.CommentCount,
        a.AnswerCount,
        u.Reputation,
        ub.BadgeCount,
        ub.BadgeNames,
        a.TotalBounty
    FROM 
        AggregatedPostData a
    JOIN 
        Users u ON a.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000  -- Only considering users with high reputation
)
SELECT 
    Title,
    DisplayName,
    CommentCount,
    AnswerCount,
    Reputation,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(BadgeNames, 'None') AS BadgeNames,
    TotalBounty
FROM 
    FinalMetrics
ORDER BY 
    TotalBounty DESC,
    CommentCount DESC;
