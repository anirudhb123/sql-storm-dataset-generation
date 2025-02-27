WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        OwnerDisplayName, 
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Popular' 
        ELSE 'Less Popular' 
    END AS PopularityStatus
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVotes DESC, 
    fp.CommentCount DESC
LIMIT 10;
