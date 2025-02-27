
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.PostTypeId IN (1, 2) 
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(VoteTypeId = 2) AS UpVotes,
        SUM(VoteTypeId = 3) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    pc.CommentCount,
    rp.Rank
FROM 
    RankedPosts rp
JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.PostId, rp.Rank;
