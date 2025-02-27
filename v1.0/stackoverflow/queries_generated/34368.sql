WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),

RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(CASE WHEN bh.Date >= NOW() - INTERVAL '1 year' THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    r.OwnerUserId,
    u.DisplayName,
    COUNT(r.Id) AS TotalPosts,
    MAX(r.Score) AS HighestScore,
    AVG(r.Score) AS AverageScore,
    SUM(r.UpVotes) AS TotalUpVotes,
    SUM(r.DownVotes) AS TotalDownVotes,
    u.PostCount,
    u.TotalScore,
    u.BadgeCount
FROM 
    RankedPosts r
JOIN 
    RecentUserActivity u ON r.OwnerUserId = u.UserId
WHERE 
    r.PostRank = 1 -- Only look at the most recent post for each user
GROUP BY 
    r.OwnerUserId, u.DisplayName, u.PostCount, u.TotalScore, u.BadgeCount
HAVING 
    SUM(r.Score) > 0 -- Only keep users with a positive total score
ORDER BY 
    TotalPosts DESC, HighestScore DESC
LIMIT 10;
