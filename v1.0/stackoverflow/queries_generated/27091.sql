WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(DISTINCT pt.PostId) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS AcceptedAnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        PostTags pt
    JOIN 
        Posts p ON p.Id = pt.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        Tag
),
TagQualities AS (
    SELECT 
        Tag,
        CASE 
            WHEN QuestionCount > 100 AND AcceptedAnswerCount > 50 THEN 'High Quality'
            WHEN QuestionCount BETWEEN 50 AND 100 AND AcceptedAnswerCount BETWEEN 20 AND 50 THEN 'Medium Quality'
            ELSE 'Low Quality'
        END AS Quality
    FROM 
        TagStatistics
),
TopTags AS (
    SELECT 
        Tag,
        Quality,
        RANK() OVER (PARTITION BY Quality ORDER BY QuestionCount DESC) AS QualityRank
    FROM 
        TagQualities
)
SELECT 
    tt.Tag,
    ts.QuestionCount,
    ts.AcceptedAnswerCount,
    ts.AverageReputation,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    tt.Quality
FROM 
    TagStatistics ts
JOIN 
    TopTags tt ON ts.Tag = tt.Tag
WHERE 
    tt.QualityRank <= 5 -- Get top 5 tags for each quality group
ORDER BY 
    tt.Quality, ts.QuestionCount DESC;
