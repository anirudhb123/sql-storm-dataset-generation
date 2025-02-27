
WITH TagSplit AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
TagCount AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        TagSplit
    GROUP BY 
        Tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        AVG(TIMESTAMPDIFF(SECOND, u.CreationDate, v.CreationDate)/86400) AS AvgPostAge 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 50  
    GROUP BY 
        u.Id
),
ActiveTags AS (
    SELECT 
        ts.Tag,
        SUM(ue.QuestionCount) AS TotalPosts,
        AVG(ue.UpvotesReceived) AS AvgUpvotes,
        AVG(ue.DownvotesReceived) AS AvgDownvotes
    FROM 
        TagCount tc
    JOIN 
        TagSplit ts ON tc.Tag = ts.Tag
    JOIN 
        UserEngagement ue ON ts.PostId = ue.UserId
    GROUP BY 
        ts.Tag
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    tc.Tag,
    tc.PostCount,
    ae.TotalPosts,
    ae.AvgUpvotes,
    ae.AvgDownvotes
FROM 
    TagCount tc
JOIN 
    ActiveTags ae ON tc.Tag = ae.Tag
ORDER BY 
    tc.PostCount DESC;
