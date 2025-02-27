-- Performance Benchmarking SQL Query

-- This query measures the performance of fetching statistics from the Posts table,
-- Including post types, user statistics, and historical edits.

WITH PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),

PostEditHistory AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edits
    GROUP BY 
        p.Id
)

SELECT 
    p.PostTypeId,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    COUNT(DISTINCT us.UserId) AS ActiveUsers,
    SUM(pes.EditCount) AS TotalEdits
FROM 
    PostStatistics ps
JOIN 
    Posts p ON p.PostTypeId = ps.PostTypeId
JOIN 
    UserStatistics us ON us.PostCount > 0
LEFT JOIN 
    PostEditHistory pes ON pes.PostId = p.Id
GROUP BY 
    p.PostTypeId, ps.TotalPosts, ps.TotalScore, ps.TotalViews, ps.AvgAnswerCount, ps.AvgCommentCount;
