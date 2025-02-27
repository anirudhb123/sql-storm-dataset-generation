WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankWithinUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId, rp.Title, rp.CommentCount, rp.UpVotes, rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankWithinUser <= 5
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(tp.PostId) AS TopPostCount,
    SUM(tp.CommentCount) AS TotalComments,
    SUM(tp.UpVotes) AS TotalUpVotes,
    SUM(tp.DownVotes) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TopPostCount DESC, TotalUpVotes DESC
LIMIT 
    10;
