WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.CommentCount, 
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fp.*, 
    u.DisplayName AS OwnerDisplayName,
    pt.Name AS PostTypeName,
    JSON_AGG(b.Name) AS BadgeNames
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.Id = u.Id
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = fp.Id LIMIT 1)
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    fp.Id, u.DisplayName, pt.Name
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
