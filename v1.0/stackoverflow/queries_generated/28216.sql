WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')::int[])
    GROUP BY 
        p.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(pt.UpVotes, 0) AS TotalUpVotes,
        COALESCE(pt.DownVotes, 0) AS TotalDownVotes,
        COALESCE(ptc.TagCount, 0) AS TotalTags,
        EXTRACT(EPOCH FROM (NOW() - p.CreationDate)) / 3600 AS PostAgeInHours
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts pt ON p.Id = pt.PostId
    LEFT JOIN 
        PostTagCounts ptc ON p.Id = ptc.PostId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.TotalTags,
    pd.PostAgeInHours,
    ROUND((pd.TotalUpVotes::decimal / NULLIF(pd.TotalTags, 0)), 2) AS UpVotesPerTagRatio,
    ROUND((pd.TotalDownVotes::decimal / NULLIF(pd.TotalTags, 0)), 2) AS DownVotesPerTagRatio
FROM 
    PostDetails pd
WHERE 
    pd.TotalTags > 0 AND
    pd.PostAgeInHours < 72 -- Filter for posts less than 72 hours old
ORDER BY 
    UpVotesPerTagRatio DESC,
    DownVotesPerTagRatio ASC
LIMIT 10;
