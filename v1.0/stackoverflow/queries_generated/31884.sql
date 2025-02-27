WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        CAST(0 AS int) AS Depth,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.AcceptedAnswerId,
        Depth + 1,
        a.CreationDate,
        a.OwnerUserId,
        a.ViewCount
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy q ON a.ParentId = q.PostId
)
, UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
, PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalViews,
    p.PostId,
    p.Title,
    p.UpVotes,
    p.DownVotes,
    p.CommentCount,
    ph.Depth,
    ph.CreationDate
FROM 
    UserActivity u
JOIN 
    PostsWithVotes p ON u.UserId = p.OwnerUserId
JOIN 
    RecursivePostHierarchy ph ON p.PostId = ph.PostId
WHERE 
    u.Rank <= 10  -- Top 10 active users
    AND ph.Depth < 3  -- Exclude deep nested answers
    AND ph.CreationDate > NOW() - INTERVAL '1 year'  -- Posts created in the last year
ORDER BY 
    u.TotalPosts DESC, 
    p.UpVotes DESC;
