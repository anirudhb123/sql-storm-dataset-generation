WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Questions from the last year
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
TaggedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        AuthorName,
        AuthorReputation,
        Score,
        CommentCount,
        Tags,
        STRING_AGG(DISTINCT SUBSTRING(tag, 2, LENGTH(tag) - 2), ', ') AS FormattedTags
    FROM 
        (SELECT 
            rp.PostId,
            rp.Title,
            rp.Body,
            rp.AuthorName,
            rp.AuthorReputation,
            rp.Score,
            rp.CommentCount,
            unnest(string_to_array(rp.Tags, ',')) AS tag
         FROM 
            RankedPosts rp) AS TagsExtract
    GROUP BY 
        PostId, Title, Body, AuthorName, AuthorReputation, Score, CommentCount
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.AuthorName,
    tp.AuthorReputation,
    tp.Score,
    tp.CommentCount,
    tp.FormattedTags,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,  -- Count of close/reopen actions
    (SELECT MAX(CreationDate) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS LastUpvoteDate  -- Last upvote date
FROM 
    TaggedPosts tp
WHERE 
    tp.CommentCount > 5  -- Only include questions with more than 5 comments
ORDER BY 
    tp.Score DESC, tp.AuthorReputation DESC;  -- Order by score and reputation
