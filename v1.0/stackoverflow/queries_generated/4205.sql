WITH UserVotes AS (
    SELECT 
        v.UserId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COALESCE(SUM(ph.UserId IS NOT NULL AND ph.PostHistoryTypeId = 11), 0) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
Summary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uv.UpVotes, 0) AS UpVoteCount,
        COALESCE(uv.DownVotes, 0) AS DownVoteCount,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.PositivePosts) AS TotalPositivePosts,
        SUM(ps.NegativePosts) AS TotalNegativePosts,
        SUM(ps.ReopenCount) AS TotalReopenedPosts
    FROM 
        Users u
    LEFT JOIN 
        UserVotes uv ON u.Id = uv.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    s.UserId,
    s.DisplayName,
    s.Reputation,
    s.UpVoteCount,
    s.DownVoteCount,
    s.TotalPosts,
    s.TotalComments,
    s.TotalPositivePosts,
    s.TotalNegativePosts,
    s.TotalReopenedPosts
FROM 
    Summary s
WHERE 
    s.Reputation > 1000
ORDER BY 
    s.Reputation DESC, s.TotalPosts DESC;
