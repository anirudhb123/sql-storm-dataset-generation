WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        UpVotes,
        DownVotes,
        0 AS Level
    FROM 
        Users 
    WHERE 
        Reputation > 100
    
    UNION ALL 
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.UpVotes,
        u.DownVotes,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputation ur ON u.UpVotes > ur.UpVotes
    WHERE 
        ur.Level < 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.CloseCount,
        ur.DisplayName,
        ur.Reputation
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.UserPostRank = 1
    JOIN 
        UserReputation ur ON u.Id = ps.Id
    WHERE 
        ps.ViewCount > 1000
    ORDER BY 
        ps.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount AS TotalViews,
    tp.UpVotes AS TotalUpVotes,
    tp.DownVotes AS TotalDownVotes,
    tp.CommentCount AS TotalComments,
    tp.CloseCount AS TotalCloseVotes,
    tp.DisplayName AS OwnerName,
    tp.Reputation AS OwnerReputation,
    CASE 
        WHEN tp.CloseCount > 0 THEN 'Post is closed'
        ELSE 'Post is active'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC

