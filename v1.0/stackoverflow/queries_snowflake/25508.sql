
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY COALESCE(p.LastActivityDate, p.CreationDate) DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Tags
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, RecentActivityRank, Tags
    FROM 
        RankedPosts
    WHERE 
        RecentActivityRank = 1
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.OwnerDisplayName,
    trp.Tags,
    SUBSTR(p.Body, 1, 300) AS ShortBody,
    COALESCE((SELECT LISTAGG(c.Text, ' | ') 
              FROM Comments c 
              WHERE c.PostId = trp.PostId), 'No comments') AS CommentPreview
FROM 
    TopRankedPosts trp
JOIN 
    Posts p ON p.Id = trp.PostId
ORDER BY 
    trp.Title ASC;
