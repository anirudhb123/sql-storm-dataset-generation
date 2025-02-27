
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(b.Name), 'No Badge') AS BadgeName
    FROM 
        Posts AS p
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    LEFT JOIN 
        Badges AS b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.BadgeName
FROM 
    PostStats AS ps
ORDER BY 
    ps.VoteCount DESC, ps.CommentCount DESC;
