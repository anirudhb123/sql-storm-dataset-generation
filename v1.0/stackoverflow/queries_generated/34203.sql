WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserId AS EditorId,
        u.DisplayName AS EditorName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    INNER JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01'
    UNION ALL
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.EditorId,
        r.EditorName,
        r.Comment
    FROM 
        RecursivePostHistory r
    INNER JOIN 
        PostHistory ph ON r.PostId = ph.PostId 
    WHERE 
        ph.CreationDate < r.CreationDate
),
FilteredPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id
),
TopEditors AS (
    SELECT 
        EditorId,
        EditorName,
        COUNT(*) AS EditCount
    FROM 
        RecursivePostHistory
    WHERE 
        EditRank = 1
    GROUP BY 
        EditorId, EditorName
    ORDER BY 
        EditCount DESC
    LIMIT 5
),
FinalResult AS (
    SELECT 
        fp.Title,
        fp.Score,
        fp.ViewCount,
        fp.CommentCount,
        te.EditorName,
        te.EditCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        TopEditors te ON fp.Id IN (SELECT PostId FROM RecursivePostHistory WHERE EditorId = te.EditorId)
)

SELECT 
    Title,
    Score,
    ViewCount,
    CommentCount,
    COALESCE(EditorName, 'No Edits') AS EditorName,
    COALESCE(EditCount, 0) AS EditCount
FROM 
    FinalResult
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;
