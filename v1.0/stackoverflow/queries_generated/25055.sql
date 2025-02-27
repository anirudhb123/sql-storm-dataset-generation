WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, pt.Name
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.Tags,
    r.CommentCount
FROM 
    Users u
JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId
WHERE 
    r.PostRank <= 3
ORDER BY 
    u.Reputation DESC, r.Score DESC;
