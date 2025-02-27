
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.TagName IN (
            SELECT value FROM STRING_SPLIT(p.Tags, '><')
        )
    GROUP BY 
        p.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Author,
    ps.CommentCount,
    ps.VoteCount,
    pt.Tags
FROM 
    PostStats ps
JOIN 
    PostTags pt ON ps.PostId = pt.PostId
ORDER BY 
    ps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
