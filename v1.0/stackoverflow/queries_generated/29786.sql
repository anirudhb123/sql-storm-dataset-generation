WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Owner,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TagDetails AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        PostId
    FROM 
        Posts
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
LIMIT 100; -- To retrieve the top 100 questions based on upvotes and close votes
