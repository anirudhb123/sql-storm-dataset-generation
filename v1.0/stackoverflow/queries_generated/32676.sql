WITH RecursivePostHierarchy AS (
    -- Step 1: Generate a hierarchical list of posts that include questions and their answers
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        rh.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rh ON p.ParentId = rh.PostId
)
-- Step 2: Calculate post score metrics and gather information on post owners
, PostMetrics AS (
    SELECT 
        rh.PostId,
        rh.Title,
        rh.Level,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY rh.Level ORDER BY COUNT(c.Id) DESC) AS Rnk
    FROM 
        RecursivePostHierarchy rh
    LEFT JOIN 
        Comments c ON c.PostId = rh.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rh.PostId
    LEFT JOIN 
        Users u ON u.Id = rh.OwnerUserId
    GROUP BY 
        rh.PostId, rh.Title, rh.Level, u.DisplayName, u.Reputation
)
-- Step 3: Select from the metrics, focusing on comments and rank
SELECT 
    pm.PostId,
    pm.Title,
    pm.Level,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    pm.OwnerDisplayName,
    pm.OwnerReputation,
    CASE 
        WHEN pm.CommentCount > 5 THEN 'Highly Engaged'
        WHEN pm.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    PostMetrics pm
WHERE 
    pm.Level = 1  -- Fetch only top-level questions
    AND (pm.CommentCount > 0 OR pm.UpVoteCount > 10)
    AND pm.Rnk <= 10  -- Limit to top 10 questions based on comment count
ORDER BY 
    pm.CommentCount DESC, pm.UpVoteCount DESC;

-- Step 4: Summary metrics over time
WITH DailyPostSummary AS (
    SELECT 
        DATE(CreationDate) AS PostDate,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        DATE(CreationDate)
)
SELECT 
    PostDate,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
FROM 
    DailyPostSummary
WHERE 
    TotalPosts > 50  -- Filter days with significant activity
ORDER BY 
    PostDate DESC;
