WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Views,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Body IS NOT NULL
        AND p.Body != ''
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostsCount,
        AVG(p.Views) AS AvgViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 questions
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        ts.TagName,
        ts.PostsCount,
        ts.AvgViews,
        ts.TotalScore,
        pu.DisplayName AS PopularUser,
        pu.QuestionsAsked,
        pu.UpvotesReceived,
        pu.DownvotesReceived
    FROM 
        RankedPosts r
    JOIN 
        TagStatistics ts ON ts.TagName = ANY(string_to_array(substring(r.Tags, 2, length(r.Tags)-2), '><'))
    LEFT JOIN 
        PopularUsers pu ON pu.UserId = r.OwnerUserId
    WHERE 
        r.rn = 1 -- Latest post for each tag
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    TagName,
    PostsCount,
    AvgViews,
    TotalScore,
    PopularUser,
    QuestionsAsked,
    UpvotesReceived,
    DownvotesReceived
FROM 
    FinalResults
ORDER BY 
    AvgViews DESC, TotalScore DESC;
