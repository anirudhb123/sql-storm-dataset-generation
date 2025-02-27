WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions only
        AND LENGTH(p.Body) > 100  -- Considering only Body text longer than 100 characters
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'  -- Checking for the tag in the post's tags
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Author,
    rp.Score,
    ts.TagName,
    ts.QuestionCount,
    ts.AvgScore,
    ts.CommentCount,
    ur.DisplayName AS UserName,
    ur.Reputation,
    ur.TotalQuestions,
    ur.PositiveScoredQuestions
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON rp.Tags LIKE '%' || ts.TagName || '%'
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.Rank <= 5 -- Selecting top 5 questions per user based on score
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;
