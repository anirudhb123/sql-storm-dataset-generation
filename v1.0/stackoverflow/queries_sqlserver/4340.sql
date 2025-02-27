
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        pd.* 
    FROM 
        PostDetails pd
    WHERE 
        pd.Rnk = 1
    ORDER BY 
        pd.Score DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    COALESCE(tp.UpVotes - tp.DownVotes, 0) AS NetVotes,
    YEAR(tp.CreationDate) AS PostYear,
    CASE 
        WHEN tp.Score > 100 THEN 'Hot'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'New'
    END AS PostStatus
FROM 
    TopPosts tp
FULL OUTER JOIN 
    Tags t ON t.ExcerptPostId = tp.PostId
WHERE 
    t.TagName IS NOT NULL
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
