
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
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
        rp.PostRank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(t.TagName, 'No Tags') AS TagName
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        STRING_AGG(t.TagName, ', ') AS TagName
    FROM 
        Tags t 
    WHERE 
        t.TagName IN (SELECT tag FROM (
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Title, ' ', n.n), ' ', -1) AS tag
            FROM 
                (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
            WHERE 
                n.n <= LENGTH(tp.Title) - LENGTH(REPLACE(tp.Title, ' ', '')) + 1
        ) AS tag_list)
) t ON TRUE
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC;
