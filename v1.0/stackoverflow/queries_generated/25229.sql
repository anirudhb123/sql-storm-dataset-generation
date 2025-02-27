WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(t.TagName) AS Tags,
        COUNT(distinct c.Id) AS CommentCount,
        COUNT(distinct a.Id) FILTER (WHERE a.PostTypeId = 2) AS AnswerCount,
        COUNT(distinct ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Tags,
        CommentCount,
        AnswerCount,
        CloseCount
    FROM
        RankedPosts
    WHERE
        RankByUser = 1 -- Only take the latest post by each user
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC
LIMIT 100; -- Fetch latest 100 posts with their status
