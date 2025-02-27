WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 -- Get top 5 posts per tag
),
TagSummary AS (
    SELECT 
        Tags,
        ARRAY_AGG(PostId) AS PostIds, 
        COUNT(PostId) AS TotalPosts,
        AVG(Score) AS AvgScore
    FROM 
        TopRankedPosts
    GROUP BY 
        Tags
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(c.Score) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.Tags,
    ts.PostIds,
    ts.TotalPosts,
    ts.AvgScore,
    ue.DisplayName AS ActiveUser,
    ue.PostsCreated,
    ue.TotalCommentScore,
    ue.TotalUpVotes
FROM 
    TagSummary ts
JOIN 
    UserEngagement ue ON ue.PostsCreated > 0
ORDER BY 
    ts.AvgScore DESC, ts.TotalPosts DESC, ue.TotalUpVotes DESC;
