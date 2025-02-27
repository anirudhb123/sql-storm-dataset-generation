WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- UpVotes and DownVotes
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month' 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY PostTypeId ORDER BY Score DESC) AS RowNum
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.Score,
    fp.CommentCount,
    fp.VoteCount
FROM 
    FilteredPosts fp
WHERE 
    fp.RowNum <= 5
ORDER BY 
    fp.PostTypeId, fp.Score DESC;
