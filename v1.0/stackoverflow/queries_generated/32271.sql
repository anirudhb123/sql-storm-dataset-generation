WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
), RecentVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        PostId
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.Rank,
        rv.UpVotes,
        rv.DownVotes,
        (rv.UpVotes - rv.DownVotes) AS VoteDifference
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.Rank = 1
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.VoteDifference,
    CASE 
        WHEN tp.VoteDifference > 0 THEN 'More UpVotes'
        WHEN tp.VoteDifference < 0 THEN 'More DownVotes'
        ELSE 'Equal Votes'
    END AS VoteStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;

-- Using an OUTER JOIN to find posts that have not received any votes
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
    AND rv.PostId IS NULL
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
