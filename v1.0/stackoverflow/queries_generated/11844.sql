-- Performance Benchmarking Query
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(b.Class) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS ModificationCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    ps.EditCount,
    ps.ModificationCount,
    ps.LastEditedDate,
    us.UpVotes,
    us.DownVotes,
    p.BadgeCount
FROM 
    UserVoteStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    PostStats ps ON p.Id = ps.PostId
JOIN 
    PostHistoryStats phs ON p.Id = phs.PostId
WHERE 
    p.CreationDate > CURRENT_DATE - INTERVAL '30 days' 
ORDER BY 
    us.VoteCount DESC, 
    p.Score DESC;
