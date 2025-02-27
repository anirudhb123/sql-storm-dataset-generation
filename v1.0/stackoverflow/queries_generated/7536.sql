WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Author,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Author,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.Author,
    tp.Score,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    EXTRACT(EPOCH FROM (NOW() - tp.CreationDate)) AS AgeInSeconds,
    CASE 
        WHEN tp.Score > 100 THEN 'High'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Rank;
