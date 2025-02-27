WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId IN (2)), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId IN (3)), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month' -- Focus on the last month
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),

PostMetrics AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        ViewCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        RankByViews,
        (ViewCount + CommentCount + UpVoteCount - DownVoteCount) AS EngagementScore
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 10 -- Get top 10 posts by views for each post type
)

SELECT 
    pm.Title,
    pm.OwnerDisplayName,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    pm.RankByViews,
    pm.EngagementScore
FROM 
    PostMetrics pm
ORDER BY 
    pm.EngagementScore DESC
LIMIT 50; -- Final selection of top engaging posts, ordered by engagement score
