WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerName,
        tp.CreationDate,
        tp.CommentCount,
        (tp.UpVotes - tp.DownVotes) AS NetVotes,
        COALESCE((SELECT AVG(u.Reputation) FROM Users u WHERE u.LastAccessDate >= NOW() - INTERVAL '1 year'), 0) AS AvgUserReputation
    FROM 
        TopPosts tp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerName,
    ps.CreationDate,
    ps.CommentCount,
    ps.NetVotes,
    ps.AvgUserReputation,
    CASE 
        WHEN ps.NetVotes > 50 THEN 'Hot'
        WHEN ps.NetVotes BETWEEN 20 AND 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostStatistics ps
ORDER BY 
    ps.NetVotes DESC
LIMIT 10;

-- This query pulls the top posts from the past year, calculates statistics on them (including net votes and average user reputation), 
-- categorizes them, and orders the results by the most popular posts.
