-- Performance benchmarking query to analyze user engagement and post activity
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,         -- Count of UpVotes
        SUM(v.VoteTypeId = 3) AS TotalDownVotes        -- Count of DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.TotalBounty,
    ue.TotalUpVotes,
    ue.TotalDownVotes,
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.VoteCount,
    pa.LastActivityDate
FROM 
    UserEngagement ue
JOIN 
    PostActivity pa ON pa.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = ue.UserId
    )
ORDER BY 
    ue.TotalPosts DESC, ue.TotalComments DESC;
