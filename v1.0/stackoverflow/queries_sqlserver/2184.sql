
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><')
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    rp.ViewCount AS RecentPostViews,
    tt.TagName
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    TopTags tt ON us.TotalPosts > 0
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.TotalUpVotes DESC, us.TotalPosts ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
