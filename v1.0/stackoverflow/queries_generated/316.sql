WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.CreationDate DESC) AS YearRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerName,
        p.CommentCount,
        p.UpVoteCount,
        p.DownVoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        RecentPosts p
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerName,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.PostRank <= 10 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostCategory,
    COALESCE(NULLIF(tp.UpVoteCount - tp.DownVoteCount, 0), NULL) AS VoteBalance
FROM 
    TopPosts tp
WHERE 
    tp.YearRank <= 5
UNION ALL
SELECT 
    NULL AS PostId,
    'Total UpVotes' AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS Score,
    NULL AS OwnerName,
    NULL AS CommentCount,
    SUM(tp.UpVoteCount) AS UpVoteCount,
    SUM(tp.DownVoteCount) AS DownVoteCount,
    'Aggregate Data' AS PostCategory,
    NULL AS VoteBalance
FROM 
    TopPosts tp
GROUP BY 
    'Aggregate Data'
ORDER BY 
    PostId ASC NULLS LAST;
