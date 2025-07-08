
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Owner,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagDetails AS (
    SELECT 
        TRIM(value) AS Tag,
        Id AS PostId
    FROM 
        Posts,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))
    WHERE 
        PostTypeId = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.Owner,
    pd.CreationDate,
    pd.Upvotes,
    pd.Downvotes,
    pd.CloseVotes,
    td.Tag
FROM 
    PostDetails pd
LEFT JOIN 
    TagDetails td ON pd.PostId = td.PostId
ORDER BY 
    pd.Upvotes DESC, 
    pd.CloseVotes DESC,
    pd.CreationDate DESC
LIMIT 100;
