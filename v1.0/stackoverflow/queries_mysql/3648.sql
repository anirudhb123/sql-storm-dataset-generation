
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostInteraction AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        us.DisplayName,
        us.TotalBounty,
        us.TotalUpVotes,
        us.TotalDownVotes,
        TIMESTAMPDIFF(DAY, rp.CreationDate, NOW()) AS DaysSinceCreation
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.PostRank = 1 AND rp.OwnerUserId = us.UserId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.DisplayName,
    pi.TotalBounty,
    pi.TotalUpVotes,
    pi.TotalDownVotes,
    pi.DaysSinceCreation,
    CASE 
        WHEN pi.Score > 10 THEN 'High Impact'
        WHEN pi.Score BETWEEN 5 AND 10 THEN 'Moderate Impact'
        ELSE 'Low Impact'
    END AS ImpactCategory,
    GROUP_CONCAT(DISTINCT CASE WHEN t.TagName IS NOT NULL THEN t.TagName ELSE 'N/A' END) AS AssociatedTags
FROM 
    PostInteraction pi
LEFT JOIN 
    Posts p ON pi.PostId = p.Id
LEFT JOIN (
        SELECT 
            DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS TagName
        FROM 
            Posts p 
        JOIN 
            (SELECT a.N + b.N * 10 n FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
            ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= n.n - 1
    ) t ON t.TagName IS NOT NULL
GROUP BY 
    pi.PostId, pi.Title, pi.CreationDate, pi.Score, pi.DisplayName, pi.TotalBounty, pi.TotalUpVotes, pi.TotalDownVotes, pi.DaysSinceCreation
HAVING 
    COUNT(t.TagName) > 0
ORDER BY 
    pi.Score DESC, pi.DaysSinceCreation ASC;
