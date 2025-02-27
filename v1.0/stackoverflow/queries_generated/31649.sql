WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreatedDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreatedDate, p.OwnerUserId, p.PostTypeId
),
BestPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreatedDate, 
        OwnerUserId, 
        PostTypeId, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpVotesRank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    bp.Title,
    u.DisplayName AS Author,
    bp.CommentCount,
    bp.UpVotes,
    bp.DownVotes,
    CASE 
        WHEN bp.UpVotes IS NOT NULL AND bp.DownVotes IS NOT NULL 
            THEN (bp.UpVotes - bp.DownVotes)
        ELSE NULL 
    END AS NetScore,
    (SELECT 
         STRING_AGG(t.TagName, ', ')
     FROM 
         Tags t
     INNER JOIN 
         Posts pt ON pt.Tags @> ARRAY[t.TagName]
     WHERE 
         pt.Id = bp.PostId) AS RelatedTags
FROM 
    BestPosts bp
INNER JOIN 
    Users u ON bp.OwnerUserId = u.Id
WHERE 
    bp.CommentCount > 5
ORDER BY 
    bp.UpVotesRank;

This query performs the following:
1. Creates a `RankedPosts` Common Table Expression (CTE) to rank posts based on their creation date and aggregate data such as the count of comments and votes.
2. It further narrows down to the `BestPosts` CTE which ranks the top 10 posts by UpVotes.
3. Finally, it selects the relevant columns to output the best posts along with their authors and the net score calculated from upvotes and downvotes while also aggregating related tags for those posts, applying filters and sorting for meaningful results.
