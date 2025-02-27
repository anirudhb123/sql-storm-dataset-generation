
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT c.Id) DESC) AS Rank 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id 
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    RankedPosts rp 
JOIN 
    Users u ON u.Id = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = rp.PostId
    )
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '>', -1)) AS TagName
     FROM 
      (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
     WHERE 
      CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n - 1) AS tagArray ON TRUE
JOIN 
    Tags t ON t.TagName = tagArray.TagName 
WHERE 
    rp.Rank <= 5
GROUP BY 
    u.DisplayName, rp.PostId, rp.Title, rp.CommentCount, rp.AnswerCount, rp.UpVotes, rp.DownVotes
ORDER BY 
    rp.CommentCount DESC, rp.AnswerCount DESC;
