
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        @row_number:=IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user_id:=p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @current_user_id := NULL) AS init
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0           
),
MostRecentPosts AS (
    SELECT 
        pr.PostId,
        pr.Title,
        pr.ViewCount,
        pr.Score,
        pr.CreationDate,
        pr.OwnerDisplayName,
        pr.OwnerReputation
    FROM 
        RankedPosts pr
    WHERE 
        pr.PostRank = 1
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS tag
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n 
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
               WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) ) n) tags ON tags.tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tags.tag
    GROUP BY 
        p.Id
),
TopQuestions AS (
    SELECT 
        mp.PostId,
        mp.Title,
        mp.ViewCount,
        mp.Score,
        mp.CreationDate,
        mp.OwnerDisplayName,
        mp.OwnerReputation,
        pt.TagCount
    FROM 
        MostRecentPosts mp
    JOIN 
        PostTagCounts pt ON mp.PostId = pt.PostId
    ORDER BY 
        mp.Score DESC, 
        mp.ViewCount DESC 
    LIMIT 10
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.ViewCount,
    tq.Score,
    tq.CreationDate,
    tq.OwnerDisplayName,
    tq.OwnerReputation,
    tq.TagCount
FROM 
    TopQuestions tq
JOIN 
    Votes v ON v.PostId = tq.PostId AND v.VoteTypeId = 2  
GROUP BY 
    tq.PostId, tq.Title, tq.ViewCount, tq.Score, tq.CreationDate, tq.OwnerDisplayName, tq.OwnerReputation, tq.TagCount
ORDER BY 
    COUNT(v.Id) DESC;
