WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END), 0) AS VoteScore,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Owner,
        CommentCount,
        VoteScore,
        RANK() OVER (ORDER BY (Score + VoteScore + CommentCount) DESC) AS PostRank
    FROM RankedPosts
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Owner,
    tp.CommentCount,
    tp.VoteScore,
    tp.PostRank,
    EXTRACT(EPOCH FROM now() - tp.CreationDate) AS AgeInSeconds
FROM TopPosts tp
WHERE tp.PostRank <= 10
ORDER BY tp.PostRank;
