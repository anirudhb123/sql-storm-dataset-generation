WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(SUM(p.ViewCount), 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT STRING_AGG(DISTINCT t.TagName, ', ') FROM Tags t WHERE t.ExcerptPostId = p.Id) AS AssociatedTags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.CommentCount,
    ua.TotalViews,
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.TotalComments,
    pe.UpVoteCount,
    pe.DownVoteCount,
    pe.AssociatedTags,
    CASE 
        WHEN ua.UpVotes > ua.DownVotes THEN 'Positive Contributor'
        WHEN ua.UpVotes < ua.DownVotes THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorStatus
FROM 
    UserActivity ua
FULL OUTER JOIN 
    PostEngagement pe ON ua.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = pe.PostId)
WHERE 
    ua.Rank <= 10 OR pe.PostId IS NOT NULL
ORDER BY 
    ua.UpVotes DESC, pe.TotalComments DESC;
