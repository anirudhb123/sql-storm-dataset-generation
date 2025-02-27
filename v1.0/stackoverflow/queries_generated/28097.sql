WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
      AND 
        p.Score > 0 -- Only questions with a positive score
),
TagStatistics AS (
    SELECT 
        TRIM(UNNEST(SPLIT_PARTS(Tags, '>')) ) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName 
    HAVING 
        COUNT(*) > 10 -- Only tags with more than 10 questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.PostId) AS AnswerCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Only users with more than 5 questions
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Author,
    ts.TagName,
    ts.TagCount,
    tu.TotalScore,
    tu.QuestionCount AS UserQuestionCount,
    tu.AnswerCount AS UserAnswerCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.TagName = ANY(STRING_TO_ARRAY(rp.Title, ' ')) -- Match tags based on Title keywords
JOIN 
    TopUsers tu ON rp.Author = tu.DisplayName
WHERE 
    rp.UserPostRank = 1 -- Only the latest post for each user
ORDER BY 
    rp.CreationDate DESC;
