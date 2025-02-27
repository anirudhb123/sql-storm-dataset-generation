WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- considering only bounty start and close
    GROUP BY 
        p.Id
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.AcceptedAnswers,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.CommentCount,
    pm.AvgBounty
FROM 
    UserActivity ua
JOIN 
    PostMetrics pm ON ua.UserId = pm.PostId
WHERE 
    pm.rn <= 5 -- Show only top 5 recent posts per user
ORDER BY 
    ua.TotalUpVotes DESC, pm.Score DESC
LIMIT 100 OFFSET 0
UNION ALL
SELECT 
    'Total' AS DisplayName,
    SUM(PostCount) AS PostCount,
    SUM(TotalUpVotes) AS TotalUpVotes,
    SUM(TotalDownVotes) AS TotalDownVotes,
    SUM(AcceptedAnswers) AS AcceptedAnswers,
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS CommentCount,
    NULL AS AvgBounty
FROM 
    UserActivity
ORDER BY 
    DisplayName;
