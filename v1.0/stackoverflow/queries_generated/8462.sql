WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TopScoringPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    t.Title,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    ps.UpVotes,
    ps.DownVotes,
    t.CommentCount
FROM 
    TopScoringPosts t
JOIN 
    PostVoteStats ps ON t.PostId = ps.PostId
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
