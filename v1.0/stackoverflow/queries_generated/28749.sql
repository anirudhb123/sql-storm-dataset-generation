WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        u.Reputation,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY PostId
    ) a ON a.PostId = p.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerName,
        rp.Reputation,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
        AND rp.CreationDate >= NOW() - INTERVAL '1 year'
),
TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT TRIM(unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))) ) AS UniqueTagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerName,
    fp.Reputation,
    fp.AnswerCount,
    fp.CommentCount,
    tc.UniqueTagCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagCounts tc ON tc.PostId = fp.PostId
ORDER BY 
    fp.Reputation DESC, fp.AnswerCount DESC, fp.CommentCount DESC;
