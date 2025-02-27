WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        LastActivityDate,
        OwnerUserId,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
PostVoteSummary AS (
    SELECT 
        p.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.OwnerUserId,
    tp.OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes
FROM 
    TopPosts tp
JOIN 
    PostVoteSummary pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
