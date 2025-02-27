WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count UpVotes
        SUM(v.VoteTypeId = 3) AS DownVotes -- Count DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FilteredTags AS (
    SELECT 
        Id,
        TagName,
        COUNT(*) AS UsageCount
    FROM 
        Tags
    GROUP BY 
        Id, TagName
    HAVING 
        COUNT(*) > 10  -- Tags used more than 10 times
),
PostDetails AS (
    SELECT 
        ph.Id AS PostId,
        ph.Title,
        ps.AnswerCount,
        ps.UpVotes,
        ps.DownVotes,
        pt.TagName,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        Posts ph
    LEFT JOIN 
        PostStatistics ps ON ph.Id = ps.Id
    LEFT JOIN 
        PostLinks pl ON ph.Id = pl.PostId
    LEFT JOIN 
        FilteredTags pt ON pl.RelatedPostId = pt.Id
    LEFT JOIN 
        UserBadges ub ON ph.OwnerUserId = ub.UserId
    WHERE 
        ph.PostTypeId = 1
)
SELECT 
    pd.Title,
    pd.AnswerCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.TagName,
    CASE 
        WHEN pd.BadgeCount > 0 THEN CONCAT('User has ', pd.BadgeCount, ' badges, highest class: ', pd.HighestBadgeClass)
        ELSE 'No badges'
    END AS UserBadgeInfo,
    COALESCE(rph.Level, 0) AS PostDepth
FROM 
    PostDetails pd
LEFT JOIN 
    RecursivePostHierarchy rph ON pd.PostId = rph.Id
ORDER BY 
    pd.UpVotes DESC,
    pd.AnswerCount DESC;
