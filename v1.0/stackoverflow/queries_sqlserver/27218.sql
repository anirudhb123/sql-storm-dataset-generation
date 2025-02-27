
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
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.ViewCount, p.OwnerUserId, p.Score
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
)
SELECT 
    t.OwnerDisplayName,
    t.TotalPosts, 
    t.TotalComments, 
    t.TotalUpvotes,
    t.TotalDownvotes,
    t.AvgViews,
    t.MaxRankByScore,
    'Owner: ' + t.OwnerDisplayName + 
    ' has ' + CONVERT(varchar, t.TotalPosts) + ' Questions, ' +
    CONVERT(varchar, t.TotalComments) + ' Comments, ' +
    CONVERT(varchar, t.TotalUpvotes) + ' Upvotes, ' +
    CONVERT(varchar, t.TotalDownvotes) + ' Downvotes, ' +
    'Average Views: ' + CONVERT(varchar, t.AvgViews) + 
    ', Max Rank: ' + CONVERT(varchar, t.MaxRankByScore) AS Summary 
FROM 
    TopOwnerStats t
ORDER BY 
    t.TotalPosts DESC;
