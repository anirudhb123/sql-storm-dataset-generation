
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01 12:34:56') AS DATETIME)  
    GROUP BY 
        p.Id, pt.Name
)
SELECT 
    PostId,
    PostType,
    VoteCount,
    CommentCount,
    UpVotes,
    DownVotes,
    BadgeCount
FROM 
    PostStats
ORDER BY 
    VoteCount DESC, 
    CommentCount DESC;
