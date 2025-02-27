
WITH PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score AS PostScore,
        p.ViewCount,
        u.Reputation AS UserReputation,
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
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
)

SELECT 
    PostId,
    Title,
    PostCreationDate,
    PostScore,
    ViewCount,
    UserReputation,
    CommentCount,
    VoteCount
FROM 
    PostInteraction
ORDER BY 
    PostScore DESC, CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
