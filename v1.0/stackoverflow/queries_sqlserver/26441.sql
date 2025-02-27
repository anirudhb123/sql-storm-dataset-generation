
WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
), 
HighEngagementQuestions AS (
    SELECT 
        rq.QuestionId,
        rq.Title,
        rq.CreationDate,
        rq.ViewCount,
        rq.OwnerDisplayName,
        rq.AnswerCount,
        rq.CommentCount
    FROM 
        RankedQuestions rq
    WHERE 
        rq.ViewCount > 1000 AND rq.AnswerCount > 5
), 
TopTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TRIM(value)
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    hq.Title AS QuestionTitle,
    hq.OwnerDisplayName,
    hq.ViewCount,
    hq.AnswerCount,
    hq.CommentCount,
    tt.TagName AS TopTag,
    tt.TagCount AS TopTagCount
FROM 
    HighEngagementQuestions hq
JOIN 
    TopTags tt ON EXISTS (
        SELECT 
            1 
        FROM 
            Posts p 
        WHERE 
            p.PostTypeId = 1 
            AND p.Tags LIKE '%' + tt.TagName + '%'
            AND p.Id = hq.QuestionId
    )
ORDER BY 
    hq.ViewCount DESC;
