WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(c.ViewCount) AS TotalViews,
        SUM(c.UpVotes) AS TotalUpVotes,
        SUM(c.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(ViewCount) AS ViewCount,
            SUM(UpVotes) AS UpVotes,
            SUM(DownVotes) AS DownVotes
        FROM 
            Posts
        GROUP BY 
            PostId) c ON p.Id = c.PostId
    GROUP BY 
        u.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.PositivePosts,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.VoteCount
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.Reputation > 100
ORDER BY 
    us.Reputation DESC, rp.Score DESC;
