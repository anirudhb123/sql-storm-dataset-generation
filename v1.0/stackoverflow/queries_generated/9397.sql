WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, a.AcceptedAnswerId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes,
    AVG(UP.Gain) AS AvgGain,
    MAX(rp.CreationDate) AS LastPostDate
FROM 
    UserStats us
JOIN 
    (SELECT 
        OwnerUserId, 
        SUM(COALESCE(Score, 0)) AS Gain 
     FROM 
        Posts 
     WHERE 
        Score IS NOT NULL 
     GROUP BY 
        OwnerUserId) UP ON us.UserId = UP.OwnerUserId
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.TotalPosts > 0
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalViews, us.TotalUpVotes, us.TotalDownVotes
ORDER BY 
    us.TotalViews DESC, us.TotalUpVotes DESC
LIMIT 10;
