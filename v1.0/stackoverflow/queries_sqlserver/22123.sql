
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounties,
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
        SUM(ISNULL(v.BountyAmount, 0)) > 0 OR COUNT(DISTINCT p.Id) > 5
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
    COALESCE(DATEDIFF(HOUR, mi.CreationDate, '2024-10-01 12:34:56'), 0) AS AgeInHours,
    mi.ViewCount,
    mi.Score,
    mi.RankScore,
    mi.DisplayName,
    mi.TotalBounties,
    mi.PostedQuestions,
    mi.ScoreCategory,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    MergedInfo mi
OUTER APPLY (
        SELECT 
            value AS TagName
        FROM 
            STRING_SPLIT((SELECT Tags FROM Posts WHERE Id = mi.PostId), '<>')
    ) t 
WHERE 
    (mi.Score IS NOT NULL AND mi.Score > 0) OR 
    (mi.TotalBounties IS NOT NULL AND mi.TotalBounties > 0)
GROUP BY 
    mi.PostId, mi.Title, mi.CreationDate, mi.ViewCount, mi.Score,
    mi.RankScore, mi.DisplayName, mi.TotalBounties, mi.PostedQuestions, mi.ScoreCategory
ORDER BY 
    mi.RankScore ASC, 
    mi.ViewCount DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;
