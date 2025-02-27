WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(u.UserStats, 0) AS UserReputation,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UserStats u ON p.OwnerUserId = u.UserId
    GROUP BY 
        p.Id, c.CommentCount, u.UserStats
),
TopPosts AS (
    SELECT 
        pm.*,
        pt.Name AS PostTypeName
    FROM 
        PostMetrics pm
    JOIN 
        PostTypes pt ON pm.PostId = pt.Id
    WHERE 
        pm.PostRank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.UserReputation,
    tp.PostTypeName,
    CASE 
        WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
        WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
WHERE 
    tp.UserReputation > 100
ORDER BY 
    tp.Score DESC
