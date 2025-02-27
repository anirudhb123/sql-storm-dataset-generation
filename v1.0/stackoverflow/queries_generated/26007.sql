WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Counting UpVotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- Counting DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only include questions
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
TagDetails AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(elem), ', ') AS TagsList
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL (
            SELECT UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS elem
        ) AS tags
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN ph.CreationDate END) AS LastModifiedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate AS PostCreationDate,
    pd.AuthorName,
    pd.AuthorReputation,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    td.TagsList,
    COALESCE(phd.LastEditDate, 'No edits') AS LastEditDate,
    COALESCE(phd.LastModifiedDate, 'Never modified') AS LastModifiedDate
FROM 
    PostDetails pd
LEFT JOIN 
    TagDetails td ON pd.PostId = td.PostId
LEFT JOIN 
    PostHistoryDetails phd ON pd.PostId = phd.PostId
ORDER BY 
    pd.CreationDate DESC  -- Order by the most recent questions
LIMIT 50;  -- Limit results for performance
