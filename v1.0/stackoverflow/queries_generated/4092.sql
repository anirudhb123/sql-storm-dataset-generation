WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
)

SELECT 
    up.OwnerId,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(rp.Score) AS AverageScore,
    MAX(rp.CreationDate) AS MostRecentPost,
    CASE
        WHEN AVG(rp.UpVoteCount) IS NULL THEN 'No Votes'
        ELSE CAST(AVG(rp.UpVoteCount) AS VARCHAR)
    END AS AverageUpVotes
FROM 
    (SELECT 
        u.Id AS OwnerId,
        b.Name AS BadgeName 
     FROM 
        Users u
     LEFT JOIN 
        Badges b ON u.Id = b.UserId 
     WHERE 
        u.Reputation >= 1000 
     GROUP BY 
        u.Id, b.Name) up
JOIN 
    RankedPosts rp ON up.OwnerId = rp.OwnerUserId
WHERE 
    rp.Rank <= 3
GROUP BY 
    up.OwnerId
HAVING 
    SUM(rp.ViewCount) > 1000
ORDER BY 
    TotalPosts DESC
LIMIT 10;
