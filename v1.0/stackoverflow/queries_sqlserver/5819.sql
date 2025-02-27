
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        Rank,
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.CommentCount,
    trp.AnswerCount,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    DATEDIFF(second, trp.CreationDate, '2024-10-01 12:34:56') / 3600.0 AS AgeInHours
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Badges b ON b.UserId = (
        SELECT TOP 1 Id FROM Users WHERE DisplayName = trp.OwnerDisplayName
    ) 
ORDER BY 
    trp.Score DESC, trp.CommentCount DESC;
