WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.LastAccessDate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.ViewCount > 1000
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankScore,
    au.DisplayName AS TopUser,
    au.TotalBadges,
    au.AvgReputation,
    pc.TotalCommentScore
FROM 
    RankedPosts rp
JOIN 
    PostComments pc ON pc.PostId = rp.PostId
JOIN 
    ActiveUsers au ON au.UserId = (
        SELECT TOP 1 UserId
        FROM Votes v 
        WHERE v.PostId = rp.PostId 
        ORDER BY v.CreationDate DESC
    )
WHERE 
    rp.RankScore <= 10 OR rp.ViewCount > 10000
ORDER BY 
    rp.RankScore, rp.ViewCount DESC;
