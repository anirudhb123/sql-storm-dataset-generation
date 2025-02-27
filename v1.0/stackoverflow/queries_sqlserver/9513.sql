
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_SPLIT(p.Tags, '<>') AS tag ON 1=1
    LEFT JOIN 
        Tags t ON tag.value = t.TagName
    WHERE 
        p.CreationDate >= SYSDATETIME() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, pt.Name, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        *,
        COUNT(*) OVER (PARTITION BY Rank) AS TotalPosts 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerDisplayName,
    TagsList,
    TotalPosts
FROM 
    TopRankedPosts
ORDER BY 
    TotalPosts DESC, Score DESC;
