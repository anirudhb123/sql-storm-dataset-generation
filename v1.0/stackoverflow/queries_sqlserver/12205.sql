
;WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ups.DisplayName,
    ups.PostCount,
    ups.VoteCount,
    ups.CommentCount
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
ORDER BY 
    ups.PostCount DESC, 
    ups.VoteCount DESC,
    ups.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
