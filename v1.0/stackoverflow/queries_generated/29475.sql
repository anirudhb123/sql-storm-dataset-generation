WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS OwnerDisplayName,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        Tags t ON POSITION(CONCAT('<', t.TagName, '>') IN rp.Tags) > 0
    WHERE 
        rp.Rank <= 5 -- Top 5 questions per tag
    GROUP BY 
        rp.PostId, rp.Title, u.DisplayName, rp.ViewCount, rp.AnswerCount, rp.CommentCount, rp.CreationDate
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.ViewCount,
    tq.AnswerCount,
    tq.CommentCount,
    tq.CreationDate,
    tq.TagsList,
    phs.EditCount,
    phs.CloseCount,
    phs.ReopenCount
FROM 
    TopQuestions tq
JOIN 
    PostHistoryStats phs ON tq.PostId = phs.PostId
ORDER BY 
    tq.ViewCount DESC,
    tq.AnswerCount DESC;
