
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        (SELECT COUNT(DISTINCT pl.RelatedPostId)
         FROM PostLinks pl
         WHERE pl.PostId = p.Id) AS RelatedPostCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
        FROM 
            Posts p 
        INNER JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    ) AS t ON TRUE
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, u.DisplayName
),
PostHistoryAggregates AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount
    FROM
        PostHistory ph
    GROUP BY ph.PostId
),
FinalPostData AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Author,
        rp.CommentCount,
        rp.AnswerCount,
        rp.RelatedPostCount,
        rp.Tags,
        ph.CloseCount,
        ph.ReopenCount,
        ph.SuggestedEditCount,
        ROW_NUMBER() OVER (ORDER BY rp.CreationDate DESC) AS RowNum
    FROM
        RankedPosts rp
    LEFT JOIN PostHistoryAggregates ph ON rp.PostId = ph.PostId 
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    Author,
    CommentCount,
    AnswerCount,
    RelatedPostCount,
    Tags,
    CloseCount,
    ReopenCount,
    SuggestedEditCount
FROM 
    FinalPostData
WHERE 
    RowNum <= 100 
ORDER BY 
    CreationDate DESC;
