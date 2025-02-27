
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        rp.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetVotes,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsAggregated
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        (SELECT TagName FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', numbers.n), ',', -1)) AS TagName
                             FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
                             WHERE CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, ',', '')) >= numbers.n - 1) AS t) AS tTagName
    ON TRUE
    WHERE 
        rp.rn = 1  
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, u.DisplayName, rp.AnswerCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.OwnerDisplayName,
        ps.AnswerCount,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        ps.NetVotes,
        ps.TagsAggregated,
        ROW_NUMBER() OVER (ORDER BY ps.NetVotes DESC, ps.TotalUpVotes DESC) AS PostRank
    FROM 
        PostStatistics ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.NetVotes,
    tp.TagsAggregated
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10  
ORDER BY 
    tp.NetVotes DESC;
