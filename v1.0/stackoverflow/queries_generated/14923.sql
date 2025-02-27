-- Performance benchmarking query to analyze post statistics and user engagement

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COUNT(b.Id) AS BadgeCount,
        COUNT(pl.Id) AS RelatedPostCount,
        MAX(p.CreationDate) AS LastActivityDate,
        p.OwnerUserId,
        p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpVoteCount) AS TotalUpVotes,
        SUM(ps.DownVoteCount) AS TotalDownVotes,
        SUM(ps.BadgeCount) AS TotalBadges,
        SUM(ps.RelatedPostCount) AS TotalRelatedPosts
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalComments,
    ue.TotalUpVotes,
    ue.TotalDownVotes,
    ue.TotalBadges,
    ue.TotalRelatedPosts
FROM 
    UserEngagement ue
ORDER BY 
    ue.TotalUpVotes DESC, 
    ue.TotalComments DESC;
