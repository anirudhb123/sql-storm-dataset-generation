WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ViewCount,
        rp.Score,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND 
        (rp.ViewCount > 100 OR rp.Score > 5)
),
TopActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 50
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    f.Title,
    f.CreationDate,
    f.LastActivityDate,
    f.ViewCount,
    f.Score,
    CASE 
        WHEN f.UpvoteCount IS NOT NULL THEN f.UpvoteCount 
        ELSE 0 
    END AS UpvoteCount,
    CASE 
        WHEN f.DownvoteCount IS NOT NULL THEN f.DownvoteCount 
        ELSE 0 
    END AS DownvoteCount,
    u.DisplayName AS OwnerName
FROM 
    FilteredPosts f
LEFT JOIN 
    TopActiveUsers u ON f.OwnerUserId = u.UserId
ORDER BY 
    f.LastActivityDate DESC;
