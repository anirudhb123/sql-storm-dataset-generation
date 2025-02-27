WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- considering only upvotes and downvotes
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
TopActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    r.VoteCount,
    t.UserId,
    t.DisplayName AS ActiveUserName,
    t.TotalScore,
    t.TotalPosts
FROM 
    RankedPosts r
JOIN 
    TopActiveUsers t ON r.OwnerUserId = t.UserId
WHERE 
    r.PostRank = 1  -- Selecting the most recent post for each user
ORDER BY 
    r.CreationDate DESC;
