WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM RankedPosts rp
    WHERE rp.TagRank <= 3 -- Only keep top 3 most recent posts per tag
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.CommentStatus,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM FilteredPosts fp
JOIN Users u ON EXISTS (
    SELECT 1 
    FROM Posts p 
    WHERE p.Id = fp.PostId AND p.OwnerUserId = u.Id
)
ORDER BY fp.UpVoteCount DESC, fp.CommentCount DESC
LIMIT 20;

-- This query generates a list of the top 20 recent questions categorized by tags, focusing on those with varying comment statuses. 
-- It ranks posts by their creation date per tag, counts comments and upvote/downvote activity, 
-- offering insights into user engagement and post performance.
