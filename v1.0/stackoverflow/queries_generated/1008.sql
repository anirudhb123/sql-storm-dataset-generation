WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBadgeClass,
    ua.TotalVotes,
    COALESCE(ua.UserRank, (SELECT COUNT(*) FROM UserActivity WHERE PostCount > ua.PostCount) + 1) AS AdjustedRank,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) OVER (PARTITION BY ua.UserId), 0) AS ClosePostCount,
    COALESCE(AVG(EXTRACT(EPOCH FROM (CASE WHEN p.CreationDate IS NOT NULL THEN p.LastActivityDate - p.CreationDate END)) / 3600), 0) AS AvgPostAgeInHours
FROM 
    UserActivity ua
LEFT JOIN 
    PostHistory ph ON ua.UserId = ph.UserId
LEFT JOIN 
    Posts p ON ph.PostId = p.Id 
WHERE 
    ua.PostCount > 10
ORDER BY 
    ua.PostCount DESC, 
    ua.TotalVotes DESC
LIMIT 50;
