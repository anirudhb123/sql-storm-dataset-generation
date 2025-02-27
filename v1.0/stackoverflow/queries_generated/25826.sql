WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY LEFT(Tags, 1) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(p.Tags, ',')::int[]) 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 5 -- Top 5 in each tag category
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(u.Reputation) AS Reputation
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.Score,
        tp.Tags,
        ups.UserId,
        ups.DisplayName AS UserDisplayName,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.Reputation
    FROM 
        TopPosts tp
    JOIN 
        UserPostStats ups ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
)
SELECT 
    *,
    CONCAT(DisplayName, ' has posted ', QuestionCount, ' questions and ', AnswerCount, ' answers. A total score of ', Reputation) AS UserStats
FROM 
    FinalResults
ORDER BY 
    CreationDate DESC
LIMIT 10;
