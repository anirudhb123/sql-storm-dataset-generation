
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_array
    LEFT JOIN 
        Tags t ON t.TagName = tag_array.tag_name
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.PostRank <= 5  
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.Tags
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(IFNULL(v.BountyAmount, 0)) AS TotalBountySpent,
        SUM(IFNULL(v.BountyAmount, 0)) / NULLIF(COUNT(DISTINCT p.Id), 0) AS AverageBountyPerPost
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL 2 YEAR
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 0
),
OverduePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.CreationDate < NOW() - INTERVAL 6 MONTH
        AND ph.PostHistoryTypeId IN (4, 5)  
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
    HAVING 
        MAX(ph.CreationDate) < NOW() - INTERVAL 6 MONTH
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    ru.DisplayName AS TopUser,
    ru.TotalBountySpent,
    ru.AverageBountyPerPost,
    op.LastEditDate
FROM 
    RecentPosts rp
LEFT JOIN 
    TopUsers ru ON ru.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    OverduePosts op ON op.Id = rp.PostId
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
