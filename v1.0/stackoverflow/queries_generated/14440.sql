-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.PostTypeId,
        us.UserId,
        us.PostsCount,
        us.BadgesCount,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVoteCount,
        ps.DownVoteCount
    FROM 
        PostStats ps
    JOIN 
        Users us ON ps.PostTypeId = CASE 
                                            WHEN ps.PostTypeId = 1 THEN 1 
                                            WHEN ps.PostTypeId = 2 THEN 2 
                                            ELSE 0 
                                        END
)
SELECT 
    p.Title,
    p.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.PostsCount,
    us.BadgesCount
FROM 
    Posts p
JOIN 
    FinalStats ps ON p.Id = ps.PostId
JOIN 
    Users us ON p.OwnerUserId = us.Id
ORDER BY 
    p.CreationDate DESC;
