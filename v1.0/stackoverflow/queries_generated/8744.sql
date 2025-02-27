WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' AND
        p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  -- Get the latest post by each user
)
SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON fp.PostId = b.UserId
ORDER BY 
    fp.UpVotes DESC, 
    fp.CommentCount DESC
LIMIT 10;
