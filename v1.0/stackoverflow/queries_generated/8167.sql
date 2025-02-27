WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalScore,
        TotalPosts,
        TotalUpVotes,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        ActiveUsers
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    r.UpVotes,
    r.DownVotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    au.UserRank
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    TopActiveUsers au ON u.Id = au.UserId
WHERE 
    r.UserPostRank <= 5
ORDER BY 
    au.UserRank, r.CreationDate DESC;
