
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount
), 

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.BountyAmount) > 0 
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        tu.TotalBounties,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Engaged'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
            ELSE 'Low Engagement' 
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.TotalBounties,
    ps.EngagementLevel,
    COALESCE(tk.TagName, 'Uncategorized') AS MainTag
FROM 
    PostStatistics ps
LEFT JOIN 
    (SELECT DISTINCT 
         SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName, 
         p.Id AS PostID
     FROM 
         Posts p 
     JOIN 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) n 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
     WHERE 
         p.Tags IS NOT NULL) tk ON ps.PostId = tk.PostID
WHERE 
    ps.TotalBounties IS NOT NULL
ORDER BY 
    ps.ViewCount DESC, ps.CreationDate ASC
LIMIT 100;
