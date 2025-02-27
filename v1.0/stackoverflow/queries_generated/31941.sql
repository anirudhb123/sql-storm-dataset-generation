WITH RecursivePostTree AS (
    -- Generate a recursive CTE to build a hierarchy of posts (questions and their answers)
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        1 AS Level,
        CAST(Title AS varchar(3000)) AS Path
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        pt.Level + 1,
        CAST(CONCAT(pt.Path, ' > ', p.Title) AS varchar(3000)) AS Path
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostTree pt ON p.ParentId = pt.Id
    WHERE 
        p.PostTypeId = 2 -- Answers only
),
PostStats AS (
    -- Aggregate post statistics: view count, answer count, and comment count for questions
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8 -- Bounty Start
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CommentCount
),
UserBadges AS (
    -- Get users with their badges
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass -- Only interested in the highest badge class
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
-- Main Query
SELECT 
    pt.Title AS QuestionTitle,
    pt.ViewCount,
    pt.AnswerCount,
    pt.CommentCount,
    u.DisplayName AS AnswererDisplayName,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    RANK() OVER (PARTITION BY pt.Id ORDER BY pt.CreationDate DESC) AS AnswerRank,
    COUNT(DISTINCT pt2.Id) AS RelatedPostCount
FROM 
    PostStats pt
LEFT JOIN 
    Posts p2 ON pt.Id = p2.ParentId
LEFT JOIN 
    Users u ON p2.OwnerUserId = u.Id -- Answerer
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostLinks pl ON pt.Id = pl.PostId -- Links to related posts
LEFT JOIN 
    Posts pt2 ON pl.RelatedPostId = pt2.Id -- Related posts
GROUP BY 
    pt.Title, pt.ViewCount, pt.AnswerCount, pt.CommentCount, u.DisplayName, ub.BadgeCount, 
    ub.HighestBadgeClass
ORDER BY 
    pt.ViewCount DESC, pt.AnswerCount DESC, pt.CommentCount DESC;
