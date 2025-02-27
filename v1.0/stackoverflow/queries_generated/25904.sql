WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT com.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments com ON com.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostHistoryDetail AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserDisplayName,
        ph.CreationDate AS RevisionDate,
        ph.Comment,
        ph.Text AS NewValue,
        p.ViewCount,
        ph.PostHistoryTypeId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Focusing on closure and reopening events
),
AggregatePostHistory AS (
    SELECT 
        p.Title,
        COUNT(CASE WHEN p.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN p.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        MAX(ph.RevisionDate) AS LastRevision
    FROM 
        PostHistoryDetail ph
    GROUP BY 
        ph.PostId, ph.Title
),
FinalMetrics AS (
    SELECT
        tg.TagName,
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalComments,
        us.UpVotes,
        us.DownVotes,
        ps.PostCount,
        ps.TotalViews,
        ps.AverageScore,
        ag.CloseCount,
        ag.ReopenCount,
        ag.LastRevision
    FROM 
        TagStatistics tg 
    JOIN 
        UserEngagement us ON us.TotalPosts > 0
    JOIN 
        AggregatePostHistory ag ON ag.Title LIKE '%' || tg.TagName || '%'
)
SELECT 
    *
FROM 
    FinalMetrics
ORDER BY 
    TotalViews DESC, AverageScore DESC;
