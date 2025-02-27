WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(AVG(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), NULL) AS FirstCloseDate
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
BenchmarkingData AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerName,
        TagsArray,
        UpVotes,
        DownVotes,
        CommentCount,
        FirstCloseDate,
        (UpVotes - DownVotes) AS NetScore,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CreationDate)) / 3600 AS AgeInHours
    FROM 
        PostDetails
)
SELECT 
    PostId,
    Title,
    OwnerName,
    TagsArray,
    UpVotes,
    DownVotes,
    NetScore,
    AgeInHours,
    CASE 
        WHEN NetScore > 0 THEN 'Positive'
        WHEN NetScore < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN AgeInHours < 24 THEN 'Recent'
        WHEN AgeInHours < 168 THEN 'Within a week'
        ELSE 'Older'
    END AS AgeCategory
FROM 
    BenchmarkingData
ORDER BY 
    NetScore DESC, CreationDate DESC
LIMIT 50;
