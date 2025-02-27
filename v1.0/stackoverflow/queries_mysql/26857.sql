
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        @row_num := IF(@prev_pt = pt.Name, @row_num + 1, 1) AS RankByViews,
        @prev_pt := pt.Name
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id,
        (SELECT @row_num := 0, @prev_pt := '') AS rn
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 MONTH) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.ViewCount, u.DisplayName, pt.Name
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
        RankByViews <= 10 
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
LIMIT 50;
