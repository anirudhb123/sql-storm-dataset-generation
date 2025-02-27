-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        pst.PostId,
        pst.PostTypeId,
        pst.Score,
        pst.ViewCount,
        pst.CommentCount,
        pst.VoteCount,
        pst.UpVotes,
        pst.DownVotes,
        us.UserId,
        us.BadgeCount,
        us.TotalUpVotes,
        us.TotalDownVotes
    FROM 
        PostStats pst
    JOIN 
        Users us ON pst.OwnerUserId = us.Id
)
SELECT 
    pa.PostId,
    pa.PostTypeId,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.VoteCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.BadgeCount,
    pa.TotalUpVotes,
    pa.TotalDownVotes,
    ROW_NUMBER() OVER (ORDER BY pa.Score DESC, pa.ViewCount DESC) AS Rank
FROM 
    PostActivity pa
ORDER BY 
    Rank
LIMIT 100;
