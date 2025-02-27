
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE) 
        AND p.PostTypeId IN (1, 2) 
),
PopularPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn = 1
    ORDER BY 
        Score DESC, ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.AnswerCount,
        ISNULL(pc.CommentCount, 0) AS CommentCount,
        pp.OwnerDisplayName
    FROM 
        PopularPosts pp
    LEFT JOIN 
        PostComments pc ON pp.PostId = pc.PostId
)

SELECT 
    *,
    CASE 
        WHEN Score > 10 THEN 'Hot'
        WHEN AnswerCount > 5 THEN 'Active'
        ELSE 'Other'
    END AS PostStatus
FROM 
    FinalResults
ORDER BY 
    Score DESC, CreationDate DESC;
