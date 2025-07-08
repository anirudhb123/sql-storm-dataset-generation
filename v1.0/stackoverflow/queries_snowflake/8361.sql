
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
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(p.Tags, '><')) AS t ON TRUE
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
    LIMIT 10
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
