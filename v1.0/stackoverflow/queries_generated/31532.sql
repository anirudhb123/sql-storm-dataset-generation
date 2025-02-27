WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        LastAccessDate,
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000  -- starting point for users with significant reputation

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Id = ur.Id  -- join back to users to build a hierarchical structure
    WHERE 
        u.Reputation < ur.Reputation  -- limit to users with lower reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 10) AS ClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS PostsCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10  -- tags used in more than 10 posts
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(ps.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(ps.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(ps.DownVoteCount, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ups.TotalComments,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    (SELECT COUNT(*)
     FROM Badges b
     WHERE b.UserId = u.Id) AS BadgeCount,
    (SELECT STRING_AGG(pt.Name, ', ')
     FROM PopularTags pt
     JOIN Posts p ON p.Tags @> CONCAT('<', pt.TagName, '>')  -- checking if tag exists in post tags
     WHERE p.OwnerUserId = u.Id) AS PopularTags,
    CASE 
        WHEN u.LastAccessDate < NOW() - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    Users u
LEFT JOIN 
    UserPostSummary ups ON u.Id = ups.UserId
WHERE 
    u.Reputation >= 500  -- Select users with a minimum reputation
ORDER BY 
    u.Reputation DESC, ups.TotalUpVotes DESC
LIMIT 50;
