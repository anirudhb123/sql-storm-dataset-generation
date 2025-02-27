WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        Unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided,
        SUM(COALESCE(v.CreationDate, 0)) AS TotalVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TagEngagement AS (
    SELECT 
        t.Tag, 
        COUNT(DISTINCT pa.UserId) AS ActiveUsers,
        COUNT(DISTINCT pa.PostId) AS PostsWithTag
    FROM 
        ProcessedTags pt
    JOIN 
        PostLinks pl ON pt.PostId = pl.PostId
    JOIN 
        Tags t ON pt.Tag = t.TagName
    JOIN (
        SELECT 
            p.Id AS PostId,
            u.Id AS UserId
        FROM
            Posts p
        JOIN 
            Users u ON p.OwnerUserId = u.Id
    ) pa ON pl.RelatedPostId = pa.PostId
    GROUP BY 
        t.Tag
)
SELECT 
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.AnswersProvided,
    ua.TotalVotesReceived,
    te.Tag,
    te.ActiveUsers,
    te.PostsWithTag
FROM 
    UserActivity ua
JOIN 
    TagEngagement te ON te.ActiveUsers > 0
ORDER BY 
    ua.TotalVotesReceived DESC,
    te.Tag;

