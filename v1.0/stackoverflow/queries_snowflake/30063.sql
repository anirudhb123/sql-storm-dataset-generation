
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 YEAR'
        AND p.ViewCount > 10
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerReputation
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 10
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerReputation,
    pvs.UpVotes,
    pvs.DownVotes,
    phd.LastEditDate,
    phd.EditCount,
    phd.CloseCount,
    CASE 
        WHEN phd.CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary pvs ON tp.PostId = pvs.PostId
LEFT JOIN 
    PostHistoryDetails phd ON tp.PostId = phd.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
