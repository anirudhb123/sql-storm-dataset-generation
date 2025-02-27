
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    OUTER APPLY (
        SELECT 
            tag_name 
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    ) AS tag_name
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.value
    WHERE 
        p.CreationDate > CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON b.UserId = u.Id
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
