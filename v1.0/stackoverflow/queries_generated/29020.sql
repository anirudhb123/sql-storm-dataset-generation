WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.AcceptedAnswerId
),

TagStats AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags tag
    JOIN 
        Posts p ON tag.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><')))  -- Use your actual tag splitting function
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        tag.TagName
),

TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.AcceptedAnswerId,
        rp.AnswerCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.AverageScore
    FROM 
        RankedPosts rp
    JOIN 
        TagStats ts ON ts.PostCount > 1 -- Only joining with tags that have more than 1 post associated
    WHERE 
        rp.Rank <= 10 -- Grab top 10 posts per tag on creation date
)

SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    AcceptedAnswerId,
    AnswerCount,
    UpvoteCount,
    DownvoteCount,
    TagName,
    PostCount,
    TotalViews,
    AverageScore
FROM 
    TopRankedPosts
ORDER BY 
    CreationDate DESC, UpvoteCount DESC
LIMIT 50;
