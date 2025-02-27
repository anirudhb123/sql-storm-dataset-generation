WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.Tags, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostTagDetails AS (
    SELECT 
        tp.PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        PostTags pt
    JOIN 
        Tags t ON pt.TagId = t.Id
    JOIN 
        TopRankedPosts tp ON pt.PostId = tp.PostId
    GROUP BY 
        tp.PostId
)
SELECT 
    trp.Title,
    CONCAT('Owner: ', trp.OwnerDisplayName) AS Owner,
    CONCAT('Score: ', trp.Score) AS PostScore,
    CONCAT('Views: ', trp.ViewCount) AS ViewStatistics,
    CONCAT('Answers: ', trp.AnswerCount, ', Comments: ', trp.CommentCount) AS Engagement,
    pt.TagsList,
    CASE 
        WHEN trp.Score > 100 THEN 'High Score Post' 
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTagDetails pt ON trp.PostId = pt.PostId
ORDER BY 
    trp.Score DESC;

**This SQL query does the following:**
1. It ranks questions based on score and view count.
2. It collects detailed statistics for the top 10 ranked questions.
3. It aggregates the associated tags of those top questions.
4. It formats and categorizes the results indicating whether they are high-scoring or regular posts, providing a comprehensive overview of the top-performing questions in the Stack Overflow schema.
