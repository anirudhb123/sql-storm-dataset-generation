WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Questions created in the last year
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerUserId, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 questions per user
),
UserScores AS (
    SELECT 
        u.Id AS UserId, 
        SUM(p.Score) AS TotalScore, 
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Score,
    tp.ViewCount, 
    tp.OwnerDisplayName,
    us.TotalScore AS UserTotalScore,
    us.TotalPosts AS UserTotalPosts
FROM 
    TopPosts tp
JOIN 
    UserScores us ON tp.OwnerUserId = us.UserId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
