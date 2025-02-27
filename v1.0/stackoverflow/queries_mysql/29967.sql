
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerName,
        rp.AnswerCount,
        rp.UpVotes - rp.DownVotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY rp.AnswerCount DESC, rp.UpVotes - rp.DownVotes DESC) AS Ranking
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1 
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.AnswerCount,
    tp.NetVotes,
    tp.CreationDate,
    GROUP_CONCAT(DISTINCT tc.TagName ORDER BY tc.TagName ASC SEPARATOR ', ') AS Tags 
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     WHERE 
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS tc ON TRUE
WHERE 
    tp.Ranking <= 10 
GROUP BY 
    tp.Title, tp.OwnerName, tp.AnswerCount, tp.NetVotes, tp.CreationDate
ORDER BY 
    tp.AnswerCount DESC;
