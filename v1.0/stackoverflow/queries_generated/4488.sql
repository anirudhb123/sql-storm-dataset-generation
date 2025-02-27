WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(u.UpVotes) AS TotalUpVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(u.DisplayName, 'Unknown User') AS Owner,
        uRep.TotalPosts,
        uRep.TotalBounties
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        UserStatistics uRep ON u.Id = uRep.UserId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.Owner,
    t.TotalPosts,
    t.TotalBounties,
    CASE 
        WHEN t.Score > 0 THEN 'Positive'
        WHEN t.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory
FROM 
    TopPostDetails t
ORDER BY 
    t.ViewCount DESC
LIMIT 20
UNION ALL
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(u.DisplayName, 'Unknown User') AS Owner,
    0 AS TotalPosts,
    0 AS TotalBounties
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.AcceptedAnswerId IS NULL
ORDER BY 
    Random()
LIMIT 10;
