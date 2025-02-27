-- Performance benchmarking query to analyze post-related activity
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(distinct b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
),
PostTypeSummary AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes,
        SUM(ps.BadgeCount) AS TotalBadges
    FROM 
        PostTypes pt
    LEFT JOIN 
        PostStats ps ON pt.Id = ps.PostTypeId
    GROUP BY 
        pt.Name
)
SELECT 
    *,
    (TotalComments::FLOAT / NULLIF(TotalPosts, 0)) AS AvgCommentsPerPost,
    (TotalVotes::FLOAT / NULLIF(TotalPosts, 0)) AS AvgVotesPerPost,
    (TotalBadges::FLOAT / NULLIF(TotalPosts, 0)) AS AvgBadgesPerPost
FROM 
    PostTypeSummary
ORDER BY 
    TotalPosts DESC;
