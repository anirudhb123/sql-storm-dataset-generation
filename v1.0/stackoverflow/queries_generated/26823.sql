WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, pt.Name
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        PostType,
        AnswerCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
                                    WHERE p.PostTypeId = 1)
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.PostType,
    rp.AnswerCount,
    rp.CommentCount,
    pt.Tags
FROM 
    RecentPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
ORDER BY 
    rp.CreationDate DESC, rp.AnswerCount DESC;
