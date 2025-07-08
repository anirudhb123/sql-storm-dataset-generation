
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL SPLIT_TO_TABLE(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::TIMESTAMP)
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
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySpent,
        SUM(COALESCE(v.BountyAmount, 0)) / NULLIF(COUNT(DISTINCT p.Id), 0) AS AverageBountyPerPost
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        v.CreationDate >= DATEADD(year, -2, '2024-10-01 12:34:56'::TIMESTAMP)
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
        p.CreationDate < DATEADD(month, -6, '2024-10-01 12:34:56'::TIMESTAMP)
        AND ph.PostHistoryTypeId IN (4, 5)  
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
    HAVING 
        MAX(ph.CreationDate) < DATEADD(month, -6, '2024-10-01 12:34:56'::TIMESTAMP)
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
