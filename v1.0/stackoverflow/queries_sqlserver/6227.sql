
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName
),
FinalResults AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.Score >= 50 THEN 'High'
            WHEN pd.Score >= 20 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        PostDetails pd
)
SELECT 
    fr.OwnerDisplayName,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.CommentCount,
    fr.UpvoteCount,
    fr.DownvoteCount,
    fr.ScoreCategory
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
