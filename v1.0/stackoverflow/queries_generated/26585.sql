WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.Score), 0) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CONCAT(rp.OwnerDisplayName, ' - ', CAST(rp.AnswerCount AS VARCHAR), ' Answers') AS Summary
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3
),
TopPosts AS (
    SELECT 
        fp.*,
        ROW_NUMBER() OVER (ORDER BY fp.TotalVotes DESC) AS VoteRank
    FROM 
        FilteredPosts fp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.CreationDate,
    tp.Summary,
    tp.TotalVotes,
    tp.VoteRank
FROM 
    TopPosts tp
WHERE 
    tp.VoteRank <= 10
ORDER BY 
    tp.TotalVotes DESC;
