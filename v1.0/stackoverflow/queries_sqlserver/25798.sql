
WITH TagSplit AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') AS TagList
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
        AVG(DATEDIFF(DAY, u.CreationDate, v.CreationDate)) AS AvgPostAge 
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
)
SELECT TOP 10
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
