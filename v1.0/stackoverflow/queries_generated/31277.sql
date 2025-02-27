WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag_array ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
        rp.PostRank <= 5  -- Top 5 Posts per PostType
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.Tags
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySpent,
        SUM(COALESCE(v.BountyAmount, 0)) / COUNT(DISTINCT p.Id) AS AverageBountyPerPost
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '2 years'
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
        p.CreationDate < NOW() - INTERVAL '6 months'
        AND ph.PostHistoryTypeId IN (4, 5)  -- Title and Body Edits
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
    HAVING 
        MAX(ph.CreationDate) < NOW() - INTERVAL '6 months'
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
