
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.AnswerCount, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        @row_number := IF(@prev_title = SUBSTRING(rp.Title, 1, 10), @row_number + 1, 1) AS TitleRank,
        @prev_title := SUBSTRING(rp.Title, 1, 10)
    FROM 
        RankedPosts rp,
        (SELECT @row_number := 0, @prev_title := '') AS vars
    WHERE 
        rp.ViewCount > 100
    ORDER BY 
        SUBSTRING(rp.Title, 1, 10), rp.VoteCount DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.VoteCount,
    fp.CreationDate,
    fp.AnswerCount,
    fp.ViewCount
FROM 
    FilteredPosts fp
WHERE 
    fp.TitleRank = 1 
ORDER BY 
    fp.VoteCount DESC, 
    fp.CreationDate DESC 
LIMIT 10;
