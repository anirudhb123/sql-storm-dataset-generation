WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '365 days' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
)
SELECT 
    fp.*,
    CASE 
        WHEN fp.UpVotes = 0 THEN 'No Upvotes'
        WHEN fp.DownVotes = 0 THEN 'No Downvotes'
        ELSE 'Mixed Votes'
    END AS VoteStatus,
    COALESCE((SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)), 0) AS CloseReopenCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
LIMIT 50;
