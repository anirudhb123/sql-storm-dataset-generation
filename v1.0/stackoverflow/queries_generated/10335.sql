-- Performance benchmarking query: Fetch user statistics along with their top posts and associated comments
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalScore,
    us.Questions,
    us.Answers,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.LastPostDate,
    tp.PostId,
    tp.Title AS TopPostTitle, 
    tp.CreationDate AS TopPostCreationDate, 
    tp.Score AS TopPostScore
FROM 
    UserStats us
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId AND tp.PostRank = 1
ORDER BY 
    us.Reputation DESC;
