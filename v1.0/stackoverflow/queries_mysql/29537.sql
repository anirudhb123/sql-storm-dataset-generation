
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY UpVotes DESC, CommentCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    PostId,
    Title,
    OwnerName,
    UpVotes,
    DownVotes,
    CommentCount,
    BadgeCount,
    LastActivityDate,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '>', numbers.n), '>', -1) AS TagName
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE 
            CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, '>', '')) >= numbers.n - 1
    ) t ON TRUE
WHERE 
    Rank <= 10  
GROUP BY 
    PostId, Title, OwnerName, UpVotes, DownVotes, CommentCount, BadgeCount, LastActivityDate
ORDER BY 
    UpVotes DESC, CommentCount DESC;
