WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -2, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.*, 
        CASE 
            WHEN rp.AnswerCount = 0 THEN 'No Answers'
            WHEN rp.Score > 10 THEN 'Highly Scored'
            ELSE 'Normal'
        END AS PostStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostsWithLinks AS (
    SELECT 
        fp.*, 
        pl.RelatedPostId
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostLinks pl ON fp.PostId = pl.PostId
)
SELECT 
    p.PostId, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.AnswerCount, 
    p.CommentCount, 
    p.PostStatus,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ' ORDER BY t.TagName) 
               FROM STRING_SPLIT(substring(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tagName
               JOIN Tags t ON t.TagName = tagName.value), 'No Tags') AS Tags,
    COUNT(DISTINCT CASE 
        WHEN pl.LinkTypeId = 3 THEN pl.RelatedPostId 
        END) AS DuplicateCount,
    MAX(CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 1 
        ELSE 0 END) AS HasCloseVote
FROM 
    PostsWithLinks p
LEFT JOIN 
    PostHistory ph ON p.PostId = ph.PostId 
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.PostStatus
HAVING 
    MAX(COALESCE(ph.CreationDate, '2000-01-01')) >= DATEADD(month, -3, GETDATE())
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
