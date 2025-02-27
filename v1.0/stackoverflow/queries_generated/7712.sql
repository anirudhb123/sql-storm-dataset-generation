WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) FILTER (WHERE ph.UserDisplayName IS NOT NULL) AS Editors,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tag_name ON TRUE -- Extracting tags from the text field
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),
VotingStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ps.Tags,
    ps.Editors,
    COALESCE(vs.TotalUpvotes, 0) AS Upvotes,
    COALESCE(vs.TotalDownvotes, 0) AS Downvotes,
    (COALESCE(vs.TotalUpvotes, 0) - COALESCE(vs.TotalDownvotes, 0)) AS NetVotes
FROM 
    PostStats ps
LEFT JOIN 
    VotingStats vs ON ps.PostId = vs.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 50;
