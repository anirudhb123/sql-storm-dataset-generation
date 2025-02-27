WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        u.Reputation AS AuthorReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, u.Reputation
    ORDER BY 
        p.CreationDate DESC
    LIMIT 100
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > (SELECT MIN(CreationDate) FROM Posts)  -- Only include history after posts were created
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Author,
    rp.AuthorReputation,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    json_agg(json_build_object(
        'UserDisplayName', phd.UserDisplayName,
        'HistoryType', phd.HistoryType,
        'HistoryDate', phd.HistoryDate,
        'Comment', phd.Comment,
        'Text', phd.Text
    )) AS EditHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Author, rp.AuthorReputation, rp.CommentCount, rp.VoteCount, rp.Tags
ORDER BY 
    rp.CreationDate DESC;
