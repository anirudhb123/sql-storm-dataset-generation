
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS TagRank,
        @prev_tag := p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_tag := '') AS rn
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate AS HistoryCreationDate,
        pht.Name AS ChangeType,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Tags,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    GROUP_CONCAT(CONCAT(ph.ChangeType, ': ', ph.Comment) SEPARATOR '; ') AS HistoryComments
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails ph ON tp.PostId = ph.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.Tags, tp.OwnerDisplayName, tp.AnswerCount
ORDER BY 
    tp.CreationDate DESC;
