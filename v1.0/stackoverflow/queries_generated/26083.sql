WITH FilteredPosts AS (
    SELECT 
        Id,
        Title,
        Tags,
        CreationDate,
        Score,
        (SELECT COUNT(*) FROM Comments WHERE PostId = Posts.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = Posts.Id AND VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = Posts.Id AND VoteTypeId = 3) AS DownVoteCount,
        LEFT(Body, 200) AS PreviewBody  -- Get the first 200 characters of the Body for preview
    FROM 
        Posts
    WHERE
        CreationDate > CURRENT_DATE - INTERVAL '1 year'  -- Filter posts from the last year
        AND PostTypeId = 1  -- Only questions
),

RankedPosts AS (
    SELECT 
        *,
        (UpVoteCount - DownVoteCount) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY Score DESC, NetVotes DESC, CreationDate ASC) AS Rank
    FROM 
        FilteredPosts
)

SELECT 
    r.Rank,
    r.Title,
    r.PreviewBody,
    r.CommentCount,
    r.Score,
    r.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
WHERE 
    r.Rank <= 10  -- Get top 10 posts based on rank
ORDER BY 
    r.Rank;
