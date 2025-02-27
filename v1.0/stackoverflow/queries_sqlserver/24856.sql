
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -90, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.RankScore,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
        AND rp.CommentCount > 5
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    COALESCE(fp.UpVotes, 0) - COALESCE(fp.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN fp.RankScore IS NULL THEN 'No Rank'
        WHEN fp.RankScore = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId 
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12)  
    AND ph.CreationDate >= DATEADD(DAY, -7, '2024-10-01 12:34:56')
ORDER BY 
    NetVotes DESC,
    fp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
