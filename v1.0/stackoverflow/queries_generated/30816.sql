WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        COALESCE(p.OwnerUserId, -1) AS OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        COALESCE(p.OwnerUserId, -1) AS OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostsWithUserBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(ub.BadgeNames, 'None') AS UserBadgeNames,
        votes.UpVotes,
        votes.DownVotes,
        r.Level AS PostLevel
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        AggregatedVotes votes ON p.Id = votes.PostId
    LEFT JOIN 
        RecursivePostHierarchy r ON p.Id = r.PostId
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.DisplayName,
    pwb.UserBadgeCount,
    pwb.UserBadgeNames,
    pwb.UpVotes,
    pwb.DownVotes,
    CASE 
        WHEN pwb.UserBadgeCount >= 5 THEN 'Experienced' 
        WHEN pwb.UserBadgeCount BETWEEN 1 AND 4 THEN 'Novice'
        ELSE 'No Badges' 
    END AS UserExperience,
    COUNT(c.Id) AS CommentCount
FROM 
    PostsWithUserBadges pwb
LEFT JOIN 
    Comments c ON pwb.PostId = c.PostId
GROUP BY 
    pwb.PostId, pwb.Title, pwb.CreationDate, 
    pwb.DisplayName, pwb.UserBadgeCount, 
    pwb.UserBadgeNames, pwb.UpVotes, pwb.DownVotes
ORDER BY 
    pwb.UpVotes DESC, pwb.DownVotes ASC, pwb.CreationDate DESC
OFFSET 0 ROWS
FETCH NEXT 50 ROWS ONLY;
