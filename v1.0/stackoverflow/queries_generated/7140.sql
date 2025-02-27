WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND u.Reputation >= 1000
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerName,
        rp.PostTypeName
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
    ORDER BY 
        rp.Score DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        tp.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.Title
)
SELECT 
    ts.Title,
    ts.CommentCount,
    ts.UpVoteCount,
    ts.DownVoteCount,
    (ts.UpVoteCount - ts.DownVoteCount) AS NetScore
FROM 
    PostStats ts
ORDER BY 
    NetScore DESC;
