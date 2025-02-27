WITH RecursivePostHistory AS (
    -- CTE to get the history of edits for each post recursively, along with the number of edits
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4,5,6) -- only considering title, body, and tags edits
),
UserPostInteraction AS (
    -- Get users who have interacted with posts and their respective interaction types
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, p.Id
),
PostTagCounts AS (
    -- Count of posts by tags, aggregated
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '>')) AS TagName,
        COUNT(*) AS PostsCount
    FROM 
        Posts
    GROUP BY 
        TagName
),
PostMetrics AS (
    -- Combine various metrics for posts
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(ph.EditRank), 0) AS TotalEdits,
        ROUND(AVG(p.ViewCount), 2) AS AverageViews
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
OverallMetrics AS (
    -- Joining everything to provide overall metrics
    SELECT 
        u.DisplayName,
        SUM(COALESCE(upti.UpVotesCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(upti.DownVotesCount, 0)) AS TotalDownVotes,
        SUM(COALESCE(upti.CommentsCount, 0)) AS TotalComments,
        SUM(COALESCE(upti.BadgesCount, 0)) AS TotalBadges,
        COUNT(DISTINCT pm.PostId) AS TotalPosts,
        SUM(pm.TotalEdits) AS TotalEdits,
        AVG(pm.AverageViews) AS AvgViewsPerPost
    FROM 
        UserPostInteraction upti
    LEFT JOIN 
        PostMetrics pm ON pm.PostId IN (SELECT UNNEST(ARRAY_AGG(upti.PostId)))
    GROUP BY 
        upti.DisplayName
)
SELECT 
    o.DisplayName,
    o.TotalUpVotes,
    o.TotalDownVotes,
    o.TotalComments,
    o.TotalBadges,
    o.TotalPosts,
    o.TotalEdits,
    o.AvgViewsPerPost,
    CASE 
        WHEN o.TotalPosts > 0 THEN ROUND(o.TotalUpVotes::decimal / o.TotalPosts, 2) 
        ELSE 0 
    END AS UpVotesPerPost,
    CASE 
        WHEN o.TotalPosts > 0 THEN ROUND(o.TotalDownVotes::decimal / o.TotalPosts, 2) 
        ELSE 0 
    END AS DownVotesPerPost
FROM 
    OverallMetrics o
ORDER BY 
    o.TotalUpVotes DESC;
