
WITH ProcessedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        p.AnswerCount,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        LISTAGG(DISTINCT pt.Name, ', ') WITHIN GROUP (ORDER BY pt.Name) AS PostTypeNames,
        LISTAGG(DISTINCT l.Name, ', ') WITHIN GROUP (ORDER BY l.Name) AS LinkTypeNames,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        LinkTypes l ON pl.LinkTypeId = l.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= '2021-01-01'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags, p.AnswerCount, p.ViewCount, p.Score, p.OwnerUserId
),
ProcessedTagData AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(t.Count) AS TotalCount,
        LISTAGG(DISTINCT u.DisplayName, ', ') WITHIN GROUP (ORDER BY u.DisplayName) AS UserNames
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || '<' || t.TagName || '>%' OR p.Tags LIKE '%' || '<' || t.TagName || '>' OR p.Tags LIKE '<' || t.TagName || '>%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.PostTypeNames,
    p.LinkTypeNames,
    p.AnswerCount,
    p.CommentCount,
    p.BadgeCount,
    t.TagId,
    t.TagName,
    t.PostCount,
    t.TotalCount,
    t.UserNames
FROM 
    ProcessedPostData p
JOIN 
    ProcessedTagData t ON p.Tags LIKE '%' || '<' || t.TagName || '>%' OR p.Tags LIKE '%' || '<' || t.TagName || '>' OR p.Tags LIKE '<' || t.TagName || '>%'
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
