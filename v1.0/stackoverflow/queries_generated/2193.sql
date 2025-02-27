WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(AVG(COALESCE(p.ViewCount, 0)), 0) AS AverageViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        ph.PostHistoryTypeId,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentChangeRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, ph.PostHistoryTypeId
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.AnswerCount,
        us.DisplayName,
        ps.HistoryCount,
        us.AverageViews
    FROM 
        PostStatistics ps
    JOIN 
        UserScores us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    WHERE 
        ps.RecentChangeRank = 1 AND 
        ps.Score >= 10 AND 
        us.TotalPosts > 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.AnswerCount,
    fp.DisplayName,
    fp.HistoryCount,
    fp.AverageViews,
    CASE 
        WHEN fp.AverageViews IS NULL THEN 'No views yet'
        WHEN fp.AverageViews BETWEEN 0 AND 100 THEN 'Low engagement'
        WHEN fp.AverageViews BETWEEN 101 AND 500 THEN 'Moderate engagement'
        ELSE 'High engagement'
    END AS EngagementLevel
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.Title ASC;
