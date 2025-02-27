
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Body, p.Tags
), 

TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(p.Id) AS TagCount,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) 
        -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n-1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
), 

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    ts.TagName,
    ts.TagCount,
    ts.AvgScore,
    ue.DisplayName AS EngagingUser,
    ue.TotalBounty,
    ue.TotalScore,
    ue.QuestionsAnswered,
    ue.CommentsMade
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.TagName IN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1) 
                                        FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                                              SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
                                              SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
                                              SELECT 10) numbers 
                                        WHERE CHAR_LENGTH(rp.Tags) -CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n-1)
LEFT JOIN 
    UserEngagement ue ON ue.UserId = (SELECT OwnerUserId FROM Posts WHERE AcceptedAnswerId = rp.PostId LIMIT 1)
WHERE 
    rp.Rank <= 100 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
