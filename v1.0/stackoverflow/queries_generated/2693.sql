WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rn <= 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdit,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(phd.LastEdit, 'No Edits') AS LastEdit,
    COALESCE(phd.ChangeTypes, 'No Changes') AS ChangeTypes,
    CASE 
        WHEN tp.Score >= 100 THEN 'Hot'
        WHEN tp.Score BETWEEN 50 AND 99 THEN 'Trending'
        ELSE 'Standard'
    END AS Popularity
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails phd ON tp.Id = phd.PostId
ORDER BY 
    tp.Score DESC, 
    tp.CommentCount DESC;
