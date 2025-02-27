
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - 30
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerName,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.OwnerName,
    tp.CreationDate,
    ISNULL(pc.CommentCount, 0) AS TotalComments,
    ISNULL(pvs.UpVotes, 0) AS TotalUpVotes,
    ISNULL(pvs.DownVotes, 0) AS TotalDownVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostVoteStats pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
