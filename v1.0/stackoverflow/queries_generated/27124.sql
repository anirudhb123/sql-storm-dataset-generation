WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS TagNames,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS YearlyRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 GROUP BY PostId) a ON p.Id = a.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, STRING_AGG(TagName, ', ') AS TagName 
         FROM PostLinks pl 
         JOIN Tags t ON pl.RelatedPostId = t.Id 
         GROUP BY PostId) AS t ON p.Id = t.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, a.AnswerCount, c.CommentCount
),
FilteredRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.ViewCount,
        rp.Score,
        rp.TagNames,
        rp.AnswerCount,
        rp.CommentCount,
        rp.YearlyRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.YearlyRank <= 5
)

SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Body,
    f.ViewCount,
    f.Score,
    f.TagNames,
    f.AnswerCount,
    f.CommentCount,
    pht.Name AS LastActionType,
    pht2.Name AS MostRecentEditType,
    MAX(ph.CreationDate) AS LastActionDate
FROM 
    FilteredRankedPosts f
LEFT JOIN 
    PostHistory ph ON f.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    (SELECT PostId, MAX(CreationDate) AS LastEditDate
     FROM PostHistory
     WHERE PostHistoryTypeId IN (4, 5, 6) -- Edits
     GROUP BY PostId) AS lastEdit ON f.PostId = lastEdit.PostId
LEFT JOIN 
    PostHistory ph2 ON f.PostId = ph2.PostId AND ph2.CreationDate = lastEdit.LastEditDate
LEFT JOIN 
    PostHistoryTypes pht2 ON ph2.PostHistoryTypeId = pht2.Id
GROUP BY 
    f.PostId, f.Title, f.CreationDate, f.Body, f.ViewCount, f.Score, 
    f.TagNames, f.AnswerCount, f.CommentCount, pht.Name, pht2.Name
ORDER BY 
    f.PostId;
