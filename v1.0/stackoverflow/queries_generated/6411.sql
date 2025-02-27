WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5
),
TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
    HAVING 
        COUNT(c.Id) > 2
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    tc.CommentCount AS TopCommentCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || pt.TagName || '%')
JOIN 
    TopComments tc ON rp.PostId = tc.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
