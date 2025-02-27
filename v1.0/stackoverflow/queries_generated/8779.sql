WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*, 
        u.DisplayName AS OwnerDisplayName,
        ut.Name AS UserTypeName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserTypes ut ON u.Reputation >= 1000 THEN UserTypes.Name = 'High'
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, u.DisplayName, rp.Title, rp.ViewCount, rp.CreationDate, ut.Name
)
SELECT 
    p.*,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    TopPosts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
GROUP BY 
    p.PostId, pt.Name, p.Title, p.ViewCount, p.CreationDate
ORDER BY 
    p.ViewCount DESC;
