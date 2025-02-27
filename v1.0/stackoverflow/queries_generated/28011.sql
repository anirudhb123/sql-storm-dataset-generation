WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_ids
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY SUM(p.ViewCount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5 -- Only consider users with more than 5 questions
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.CommentCount,
    r.AnswerCount,
    r.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.TotalViews,
    u.TotalAnswers,
    u.UserRank,
    r.UserPostRank
FROM 
    RankedPosts r
JOIN 
    TopUsers u ON r.OwnerUserId = u.UserId
WHERE 
    r.UserPostRank <= 3 -- Top 3 ranked posts per user
ORDER BY 
    u.UserRank, r.ViewCount DESC;
