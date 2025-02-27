WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
), TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalTagViews
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(t.TagName IN p.Tags) > 0
    GROUP BY 
        t.Id
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.TotalViews,
    ua.UpVoteCount,
    ua.DownVoteCount,
    ua.CommentCount,
    ts.TagName,
    ts.PostCount,
    ts.TotalTagViews,
    COALESCE(rph.LastEditDate, 'No Edits') AS LastEditDate
FROM 
    UserActivity ua
FULL OUTER JOIN 
    TagStatistics ts ON ua.QuestionCount > 0
LEFT JOIN 
    RecentPostHistory rph ON ua.UserId = rph.PostId
WHERE 
    ua.TotalViews IS NOT NULL
ORDER BY 
    ua.TotalViews DESC, 
    ua.UpVoteCount DESC
LIMIT 100;

-- Additional statistics about posts and their history
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.Score,
    pe.CommentCount,
    pe.UniqueVoterCount,
    CASE 
        WHEN pe.Score > 100 THEN 'Highly Engaged'
        WHEN pe.Score BETWEEN 50 AND 100 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    pe.AvgBounty
FROM 
    PostEngagement pe
WHERE 
    pe.CommentCount > 10
ORDER BY 
    pe.Score DESC
LIMIT 50;
