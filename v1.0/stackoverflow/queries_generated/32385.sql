WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        row_number() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    COALESCE(ua.PostCount, 0) AS PostCount,
    COALESCE(ua.TotalScore, 0) AS TotalScore,
    COALESCE(ua.AverageScore, 0) AS AverageScore,
    CASE 
        WHEN ua.PostCount IS NULL THEN 'No Activity'
        WHEN ua.PostCount > 10 THEN 'Active Contributor'
        ELSE 'Moderate Contributor'
    END AS ActivityLevel,
    NULLIF(MAX(p.Score), 0) AS MaxPostScore,
    STRING_AGG(DISTINCT p.Tags, ', ') AS Tags
FROM 
    UserActivity ua
LEFT JOIN 
    Posts p ON ua.UserId = p.OwnerUserId
GROUP BY 
    ua.UserId, ua.DisplayName
ORDER BY 
    TotalScore DESC
LIMIT 100;
