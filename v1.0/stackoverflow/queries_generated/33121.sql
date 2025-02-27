WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
HistoryAggregates AS (
    SELECT 
        postId,
        COUNT(CASE WHEN pht.Name = 'Edit Title' THEN 1 END) AS EditTitleCount,
        COUNT(CASE WHEN pht.Name = 'Edit Body' THEN 1 END) AS EditBodyCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        postId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.PostRank,
    ra.EditTitleCount,
    ra.EditBodyCount,
    ra.LastEditedDate,
    rv.VoteCount,
    rv.UpVotes,
    rv.DownVotes,
    CASE 
        WHEN rv.UpVotes IS NULL THEN 0 
        ELSE rv.UpVotes 
    END AS UpVotesOrZero,
    CASE 
        WHEN rv.DownVotes IS NULL THEN 0 
        ELSE rv.DownVotes 
    END AS DownVotesOrZero,
    rp.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    HistoryAggregates ra ON rp.PostId = ra.postId
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OPTION (RECOMPILE);

