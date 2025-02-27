WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, U.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Owner,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC, CommentCount DESC) AS OverallRank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.*
FROM 
    TopPosts tp
JOIN 
    Tags t ON tp.Title LIKE '%' + t.TagName + '%'
ORDER BY 
    tp.OverallRank, tp.CreationDate DESC;
