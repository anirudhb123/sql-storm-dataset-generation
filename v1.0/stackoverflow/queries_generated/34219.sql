WITH RecursivePostCTE AS (
    -- Recursive CTE to get the hierarchy of posts (questions and their answers)
    SELECT 
        Id,
        Title,
        PostTypeId,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
PostVoteCounts AS (
    -- CTE to count upvotes and downvotes for posts
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStats AS (
    -- CTE to gather statistics per post
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(pl.RelatedPostId IS NOT NULL), 0) AS RelatedPostCount,
        MAX(p.CreationDate) as LatestActivity
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts pv ON p.Id = pv.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, pv.UpVotes, pv.DownVotes
),
MostActiveUsers AS (
    -- CTE to find users with the most posts and interactions
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(pv.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(pv.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts pv ON p.Id = pv.PostId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.RelatedPostCount,
    mus.DisplayName AS TopUser,
    mus.TotalPosts,
    mus.TotalUpVotes,
    mus.TotalDownVotes,
    RANK() OVER (ORDER BY ps.UpVotes DESC) AS VoteRank,
    CASE 
        WHEN ps.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM 
    PostStats ps 
LEFT JOIN 
    Tags t ON ps.PostId = t.ExcerptPostId
JOIN 
    MostActiveUsers mus ON ps.PostId = (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = mus.UserId 
        ORDER BY 
            p.Score DESC 
        LIMIT 1
    )
GROUP BY 
    ps.PostId, ps.Title, ps.UpVotes, ps.DownVotes, ps.CommentCount, ps.RelatedPostCount, mus.DisplayName, mus.TotalPosts, mus.TotalUpVotes, mus.TotalDownVotes
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC;
