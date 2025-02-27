WITH TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(CHAR_LENGTH(p.Body), 0)) AS AvgPostLength,
        AVG(DATE_PART('epoch', p.LastActivityDate - p.CreationDate)) AS AvgPostAgeSeconds
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- considering only upvotes for summary
    WHERE 
        p.PostTypeId = 1  -- only questions
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalViews,
        AvgPostLength,
        AvgPostAgeSeconds,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS PopularityRank
    FROM 
        TagSummary
),
Engagement AS (
    SELECT 
        t.TagName,
        t.PostCount,
        t.TotalUpVotes,
        t.TotalDownVotes,
        t.TotalViews,
        t.AvgPostLength,
        t.AvgPostAgeSeconds,
        u.Reputation AS OwnerReputation,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        TopTags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName, t.PostCount, t.TotalUpVotes, t.TotalDownVotes, t.TotalViews, t.AvgPostLength, t.AvgPostAgeSeconds, u.Reputation
)
SELECT 
    e.TagName,
    e.PostCount,
    e.TotalUpVotes,
    e.TotalDownVotes,
    e.TotalViews,
    e.AvgPostLength,
    e.AvgPostAgeSeconds,
    e.OwnerReputation,
    e.AcceptedAnswerCount
FROM 
    Engagement e
WHERE 
    e.PostCount > 10 -- consider only tags with more than 10 posts
ORDER BY 
    e.TotalUpVotes DESC, e.PostCount DESC;
