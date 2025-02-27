WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
           u.DisplayName AS Author, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, u.DisplayName
), TopPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 5
), PostDetails AS (
    SELECT tp.Title, tp.Author, tp.CreationDate, 
           COALESCE(NULLIF(tp.ViewCount, 0), 1) AS ViewCount, 
           tp.Score, tp.CommentCount, tp.UpVotes, tp.DownVotes,
           (tp.UpVotes - tp.DownVotes) AS NetVotes,
           pt.Name AS PostTypeName
    FROM TopPosts tp
    JOIN PostTypes pt ON tp.PostTypeId = pt.Id
)
SELECT pd.Title, pd.Author, pd.CreationDate, 
       pd.ViewCount, pd.Score, pd.CommentCount, 
       pd.UpVotes, pd.DownVotes, pd.NetVotes, pd.PostTypeName
FROM PostDetails pd
ORDER BY pd.Score DESC, pd.CreationDate DESC;
