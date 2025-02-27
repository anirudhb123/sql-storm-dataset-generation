
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  
    GROUP BY
        u.Id,
        u.DisplayName
    HAVING 
        SUM(COALESCE(v.BountyAmount, 0)) > 0 OR COUNT(DISTINCT p.Id) > 5
),
MergedInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        pu.DisplayName,
        pu.TotalBounties,
        pu.PostedQuestions,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score'
            WHEN rp.Score <= 5 THEN 'Low'
            WHEN rp.Score BETWEEN 6 AND 15 THEN 'Medium'
            ELSE 'High'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PopularUsers pu ON rp.OwnerUserId = pu.UserId
)
SELECT 
    mi.PostId,
    mi.Title,
    COALESCE(TIMESTAMPDIFF(SECOND, mi.CreationDate, '2024-10-01 12:34:56') / 3600, 0) AS AgeInHours,
    mi.ViewCount,
    mi.Score,
    mi.RankScore,
    mi.DisplayName,
    mi.TotalBounties,
    mi.PostedQuestions,
    mi.ScoreCategory,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    MergedInfo mi
LEFT JOIN (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', numbers.n), '<>', -1)) AS TagName
        FROM 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
        JOIN 
            Posts ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= numbers.n - 1
    ) t ON true 
WHERE 
    (mi.Score IS NOT NULL AND mi.Score > 0) OR 
    (mi.TotalBounties IS NOT NULL AND mi.TotalBounties > 0)
GROUP BY 
    mi.PostId, mi.Title, mi.CreationDate, mi.ViewCount, mi.Score,
    mi.RankScore, mi.DisplayName, mi.TotalBounties, mi.PostedQuestions, mi.ScoreCategory
ORDER BY 
    mi.RankScore ASC, 
    mi.ViewCount DESC
LIMIT 100 OFFSET 0;
