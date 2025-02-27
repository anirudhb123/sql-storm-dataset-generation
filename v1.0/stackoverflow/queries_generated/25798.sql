WITH TagSplit AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- We're only interested in Questions
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
        SUM(v.VoteTypeId = 2) AS UpvotesReceived,
        SUM(v.VoteTypeId = 3) AS DownvotesReceived,
        AVG(v.CreationDate - u.CreationDate) AS AvgPostAge 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions only
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 50  -- Look at users with a significant reputation
    GROUP BY 
        u.Id
),
ActiveTags AS (
    SELECT 
        t.Tag,
        SUM(ue.QuestionCount) AS TotalPosts,
        AVG(ue.UpvotesReceived) AS AvgUpvotes,
        AVG(ue.DownvotesReceived) AS AvgDownvotes
    FROM 
        TagCount tc
    JOIN 
        TagSplit ts ON tc.Tag = ts.Tag
    JOIN 
        UserEngagement ue ON ts.PostId IN (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.Id = ts.PostId
        )
    GROUP BY 
        t.Tag
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    t.Tag,
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
