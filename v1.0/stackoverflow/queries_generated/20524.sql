WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id
),

PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEditDate,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 6, 10) -- Edit Title, Edit Tags, Post Closed
    GROUP BY 
        ph.PostId
),

OverlappedPosts AS (
    SELECT 
        p1.Id AS PostId,
        p1.Title,
        CASE 
            WHEN p1.ViewCount > 1000 THEN 'Highly Viewed'
            ELSE 'Moderately Viewed'
        END AS ViewCategory,
        PH.RevisionCount,
        PH.LastEditDate,
        PH.Editors
    FROM 
        RankedPosts p1
    JOIN 
        PostHistoryAggregates PH ON p1.PostId = PH.PostId
    WHERE 
        p1.Score >= 10 OR PH.RevisionCount >= 5
    UNION ALL
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        'Low Activity' AS ViewCategory,
        NULL AS RevisionCount,
        NULL AS LastEditDate,
        NULL AS Editors
    FROM 
        Posts p2
    WHERE 
        p2.ViewCount IS NULL OR p2.CreationDate < CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    OP.PostId,
    OP.Title,
    OP.ViewCategory,
    COALESCE(OP.RevisionCount, 0) AS RevisionCount,
    COALESCE(OP.LastEditDate, 'Never Edited') AS LastEditDate,
    CASE 
        WHEN OP.Editors IS NULL THEN 'No Editors'
        ELSE array_to_string(OP.Editors, ', ')
    END AS EditorNames,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8) AS TotalBountyAmount
FROM 
    OverlappedPosts OP
LEFT JOIN 
    Comments c ON OP.PostId = c.PostId
LEFT JOIN 
    Votes v ON OP.PostId = v.PostId
GROUP BY 
    OP.PostId, OP.Title, OP.ViewCategory, OP.RevisionCount, OP.LastEditDate, OP.Editors
ORDER BY 
    OP.ViewCategory, COUNT(DISTINCT c.Id) DESC, OP.LastEditDate DESC;
