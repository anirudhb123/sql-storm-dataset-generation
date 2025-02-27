WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.AboutMe,
        u.Location,
        1 AS ActivityLevel
    FROM 
        Users u
    WHERE 
        u.CreationDate < NOW() - INTERVAL '1 year'
    
    UNION ALL
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.AboutMe,
        u.Location,
        ra.ActivityLevel + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserActivity ra ON u.Id = ra.UserId
    WHERE 
        ra.ActivityLevel < 5
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEdit,
        MAX(ph.CreationDate) AS LastEdit,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(pm.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(pm.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(pm.AvgBounty, 0)) AS TotalAvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostMetrics pm ON pm.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.ActivityLevel,
    ups.PostCount,
    ups.TotalComments,
    ups.TotalVotes,
    ups.TotalAvgBounty,
    COALESCE(phs.FirstEdit, 'No Edits') AS FirstEdit,
    COALESCE(phs.LastEdit, 'No Edits') AS LastEdit,
    phs.RevisionCount
FROM 
    RecursiveUserActivity ua
LEFT JOIN 
    UserPostSummary ups ON ua.UserId = ups.UserId
LEFT JOIN 
    PostHistorySummary phs ON ups.PostCount > 0
WHERE 
    ua.Reputation > 100
ORDER BY 
    ua.Reputation DESC, ups.PostCount DESC;
