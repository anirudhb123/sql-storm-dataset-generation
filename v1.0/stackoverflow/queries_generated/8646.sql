WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
CommentedPosts AS (
    SELECT
        rp.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId
),
PostWithVoteCounts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 6) AS CloseVoteCount
    FROM
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.CreationDate,
    rp.Score,
    cp.CommentCount,
    pvc.UpVotes,
    pvc.DownVotes,
    pvc.CloseVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostWithVoteCounts pvc ON rp.PostId = pvc.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
