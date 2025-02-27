WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.AcceptedAnswerId,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosureDate,
        STRING_AGG(DISTINCT ph.UserDisplayName || ': ' || ph.Comment, '; ') AS ClosureComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.AcceptedAnswerId, u.DisplayName
),

PostSummary AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Author,
        pd.CreationDate,
        pd.CommentCount,
        pd.VoteCount,
        pd.TagList,
        pd.ClosureDate,
        pd.ClosureComments,
        CASE
            WHEN pd.VoteCount >= 10 THEN 'Highly Voted'
            WHEN pd.VoteCount BETWEEN 5 AND 9 THEN 'Moderately Voted'
            WHEN pd.VoteCount < 5 THEN 'Low Votes'
        END AS VoteCategory
    FROM 
        PostDetails pd
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.TagList,
    ps.ClosureDate,
    ps.ClosureComments,
    ps.VoteCategory
FROM 
    PostSummary ps
WHERE 
    ps.ClosureDate IS NOT NULL -- Only include closed posts
ORDER BY 
    ps.ClosureDate DESC,
    ps.VoteCount DESC;
