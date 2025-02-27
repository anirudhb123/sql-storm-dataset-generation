WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS NumPosts,
        COUNT(DISTINCT c.Id) AS NumComments,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS NumVotes,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.OwnerName
    FROM 
        PostDetails pd
    WHERE 
        pd.rn <= 5
)
SELECT 
    ua.DisplayName AS UserName,
    ua.NumPosts,
    ua.NumComments,
    ua.NumVotes,
    ua.TotalBadges,
    ua.AvgReputation,
    tp.Title AS RecentPostTitle,
    tp.CreationDate AS RecentPostDate,
    tp.Score AS RecentPostScore,
    tp.ViewCount AS RecentPostViews,
    tp.OwnerName AS PostOwner
FROM 
    UserActivity ua
LEFT JOIN 
    TopPosts tp ON ua.UserId = tp.OwnerName
ORDER BY 
    ua.AvgReputation DESC, ua.NumPosts DESC
LIMIT 10;
