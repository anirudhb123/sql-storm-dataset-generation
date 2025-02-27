WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        pvs.UpVotes,
        pvs.DownVotes,
        rp.OwnerDisplayName,
        (pvs.UpVotes - pvs.DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.UpVotes,
    tp.DownVotes,
    tp.NetVotes,
    tp.OwnerDisplayName,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(SUM(ph.CreatedDate), 'No History') AS PostHistory
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON tp.PostId = c.PostId
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.UpVotes, tp.DownVotes, tp.NetVotes, tp.OwnerDisplayName, c.CommentCount
ORDER BY 
    tp.NetVotes DESC;
