
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 2 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
), PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
), RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        DENSE_RANK() OVER (ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= CURDATE() - INTERVAL 1 MONTH
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    (SELECT GROUP_CONCAT(tag.TagName SEPARATOR ', ') 
        FROM PopularTags tag 
        JOIN Posts post ON post.Tags LIKE CONCAT('%', tag.TagName, '%')
        WHERE post.Id = rp.PostId) AS PopularTags,
    (SELECT r.ActivityRank
        FROM RecentActivity r
        WHERE r.PostId = rp.PostId) AS RecentActivityRank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
