WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(vt.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(vt.VoteTypeId = 3), 0) AS DownVotes,
        ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes vt ON vt.PostId = p.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON t.TagName IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Filter for title, body, and tag edits
    GROUP BY 
        ph.PostId
),
PostPerformance AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.Author,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        pa.CreationDate,
        re.LastEditDate,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - pa.CreationDate)) / 86400 AS DaysSinceCreation,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - re.LastEditDate)) / 86400 AS DaysSinceLastEdit
    FROM 
        PostAnalytics pa
    LEFT JOIN 
        RecentEdits re ON pa.PostId = re.PostId
)
SELECT 
    PostId,
    Title,
    Author,
    CommentCount,
    UpVotes,
    DownVotes,
    DaysSinceCreation,
    DaysSinceLastEdit,
    CASE 
        WHEN DaysSinceLastEdit < 7 THEN 'Recently Edited'
        WHEN DaysSinceCreation < 30 THEN 'New'
        ELSE 'Established'
    END AS PostStatus
FROM 
    PostPerformance
WHERE 
    UpVotes > DownVotes
ORDER BY 
    UpVotes DESC, DaysSinceCreation ASC;
