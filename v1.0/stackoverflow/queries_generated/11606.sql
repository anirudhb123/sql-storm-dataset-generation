WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN c.UserId = u.Id THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.Title,
    p.CreationDate,
    p.CommentCount AS TotalComments,
    p.VoteCount AS TotalVotes,
    p.UpVotes,
    p.DownVotes,
    u.DisplayName AS OwnerDisplayName,
    u.BadgeCount,
    u.PostCount AS OwnerPostCount,
    u.CommentCount AS OwnerCommentCount
FROM 
    PostStats p
JOIN 
    Users u ON p.OwnerUserId = u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
