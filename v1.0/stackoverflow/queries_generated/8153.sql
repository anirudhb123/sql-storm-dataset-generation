WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(v.VoteTypeId = 6) AS CloseVotes,
        SUM(v.VoteTypeId = 7) AS ReopenVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag(t) ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.t
    GROUP BY 
        p.Id, pt.Name
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.PostType,
        u.DisplayName AS Owner,
        ua.TotalPosts,
        ua.TotalComments
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE Id = ps.PostId)
    JOIN 
        UserActivity ua ON u.Id = ua.UserId
    WHERE 
        ps.Score > 10
    ORDER BY 
        ps.Score DESC
    LIMIT 10
)
SELECT 
    t.Title,
    t.CreationDate,
    t.Owner,
    t.Score,
    t.ViewCount,
    t.TotalPosts,
    t.TotalComments,
    t.PostType,
    t.Tags
FROM 
    TopPosts t;
