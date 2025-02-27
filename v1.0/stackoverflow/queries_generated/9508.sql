WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (UpVoteCount - DownVoteCount) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 AND rp.Score > 0
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.PostType,
    fp.Score,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.NetVotes
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.CommentCount DESC;
