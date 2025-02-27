WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
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
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        CreationDate
    FROM 
        RankedPosts 
    WHERE 
        OwnerPostRank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CreationDate,
    -- Joining on PostHistory to get the latest edit info
    ph.UserDisplayName AS LastEditor,
    ph.CreationDate AS LastEditDate 
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE PostId = tp.PostId
    )
ORDER BY 
    tp.CreationDate DESC;
