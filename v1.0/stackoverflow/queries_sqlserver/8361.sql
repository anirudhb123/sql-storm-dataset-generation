
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS APPLY 
        (SELECT value AS TagName 
         FROM STRING_SPLIT(p.Tags, '><')) AS t
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        (ps.ViewCount + ps.Score + ps.CommentCount + ps.VoteCount) AS EngagementScore
    FROM 
        PostStats ps
    ORDER BY 
        EngagementScore DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tp.PostId,
    tp.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags 
FROM 
    TopPosts tp
JOIN 
    PostStats ps ON tp.PostId = ps.PostId;
