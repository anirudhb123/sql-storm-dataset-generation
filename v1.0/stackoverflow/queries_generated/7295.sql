WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT l.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks l ON p.Id = l.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalBadges,
    ur.TotalPosts,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.RelatedPostsCount
FROM 
    UserReputation ur
JOIN 
    PostDetails pd ON ur.UserId = pd.OwnerDisplayName
ORDER BY 
    ur.TotalBadges DESC, ur.TotalPosts DESC, pd.Score DESC
LIMIT 100;
