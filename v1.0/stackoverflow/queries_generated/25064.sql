WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only consider questions
        AND p.Score > 0   -- Only questions with a score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Only users with more than 5 questions
),
TaggedPosts AS (
    SELECT 
        tp.UserId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        tp.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.TotalScore,
    rp.Title AS TopPostTitle,
    rp.Tags AS PostTags,
    rp.CreationDate AS PostCreationDate,
    tp.Tags AS UserTags
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.RankByScore = 1  -- Top scored question
LEFT JOIN 
    TaggedPosts tp ON tu.UserId = tp.UserId
ORDER BY 
    tu.TotalScore DESC, tu.TotalQuestions DESC;

This SQL query performs a multi-stage aggregation process to retrieve data about users who have asked a significant number of questions on Stack Overflow. It identifies the top questions per user based on score and aggregates tags associated with those users' questions. The final output includes the top scoring question, its creation date, and relevant tags per user, sorted by total score and question count.
