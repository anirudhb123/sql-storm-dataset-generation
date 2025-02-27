WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankForOwner
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') t ON TRUE
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Focusing only on Questions
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate
    ORDER BY 
        p.Score DESC
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(c.CommentCount) AS TotalComments,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
    ORDER BY 
        TotalComments DESC
)
SELECT 
    r.PostId,
    r.Title,
    r.Owner,
    r.CreationDate,
    r.CommentCount,
    r.VoteCount,
    r.TagList,
    a.UserId,
    a.DisplayName AS ActiveUser,
    a.QuestionCount,
    a.AnswerCount,
    a.TotalComments,
    a.BadgeCount
FROM 
    RankedPosts r
JOIN 
    MostActiveUsers a ON a.UserId = r.OwnerUserId
WHERE 
    r.RankForOwner = 1
ORDER BY 
    r.VoteCount DESC, r.CommentCount DESC;

This query performs a benchmark on string processing and user activity within the Stack Overflow schema. It includes several Common Table Expressions (CTEs) to rank posts by comments and votes, while also identifying the most active users based on their engagement with questions and comments. Then, it combines this information to provide a comprehensive view of popular posts along with user statistics, suitable for analyzing string manipulation in titles and tags.
