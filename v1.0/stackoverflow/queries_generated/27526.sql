WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.OwnerPostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    (tp.UpVotes - tp.DownVotes) AS NetVotes,
    CASE
        WHEN tp.UpVotes > tp.DownVotes THEN 'Positively Received'
        WHEN tp.UpVotes < tp.DownVotes THEN 'Negatively Received'
        ELSE 'Neutral'
    END AS Reception,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p
     JOIN Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))
     WHERE p.Id = tp.PostId) AS Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC
LIMIT 10;
