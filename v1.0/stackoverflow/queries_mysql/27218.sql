
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.OwnerUserId, p.Score
),
TopOwnerStats AS (
    SELECT
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(UpvoteCount) AS TotalUpvotes,
        SUM(DownvoteCount) AS TotalDownvotes,
        AVG(ViewCount) AS AvgViews,
        MAX(RankByScore) AS MaxRankByScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    t.OwnerDisplayName,
    t.TotalPosts, 
    t.TotalComments, 
    t.TotalUpvotes,
    t.TotalDownvotes,
    t.AvgViews,
    t.MaxRankByScore,
    CONCAT('Owner: ', t.OwnerDisplayName, 
           ' has ', t.TotalPosts, ' Questions, ',
           t.TotalComments, ' Comments, ',
           t.TotalUpvotes, ' Upvotes, ',
           t.TotalDownvotes, ' Downvotes, ',
           'Average Views: ', t.AvgViews, 
           ', Max Rank: ', t.MaxRankByScore) AS Summary 
FROM 
    TopOwnerStats t
ORDER BY 
    t.TotalPosts DESC;
