
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS AuthorName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Tags,
        rp.AuthorName,
        rp.Reputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3 
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(c.Text SEPARATOR ' ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(CONCAT(ph.CreationDate, ' - ', ph.Comment) SEPARATOR ' | ') AS EditHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Tags,
    tp.AuthorName,
    tp.Reputation,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pc.AllComments, '') AS AllComments,
    COALESCE(ph.EditHistory, '') AS EditHistory
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryAggregated ph ON tp.PostId = ph.PostId
ORDER BY 
    tp.Reputation DESC, tp.CreationDate DESC;
