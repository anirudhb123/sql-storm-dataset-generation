WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostType,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5' 
            ELSE 'Others' 
        END AS Grouping
    FROM RankedPosts rp
    JOIN PostTypes pt ON rp.PostTypeId = pt.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.PostType,
    tp.Grouping
FROM TopPosts tp
WHERE tp.Grouping = 'Top 5' 
ORDER BY tp.Score DESC, tp.CreationDate DESC;
