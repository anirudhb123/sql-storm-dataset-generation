WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pa.AnswerCount, 0) AS TotalAnswers,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId) pc ON p.Id = pc.PostId
    LEFT JOIN 
        (SELECT 
            ParentId, COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId) pa ON p.Id = pa.ParentId
    WHERE 
        p.PostTypeId = 1
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        (SELECT 
            UNNEST(string_to_array(Tags, '|')) AS TagName, Id 
         FROM 
            Posts) pt ON t.TagName = pt.TagName
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.Score,
    rp.TotalComments,
    rp.TotalAnswers,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE CONCAT('%', pt.TagName, '%'))
WHERE 
    rp.ScoreRank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.TotalAnswers DESC;
