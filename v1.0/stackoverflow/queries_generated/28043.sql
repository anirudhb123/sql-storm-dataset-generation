WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(NULLIF(pb.UserId, -1), p.OwnerUserId) AS ActualOwnerId,
        u.DisplayName AS ActualOwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    LEFT JOIN 
        Votes v2 ON p.Id = v2.PostId AND v2.VoteTypeId = 3 -- Downvotes
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
FilteredPosts AS (
    SELECT 
        *,
        (SELECT COUNT(*)
         FROM Comments c 
         WHERE c.PostId = rp.PostId) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                         WHEN v.VoteTypeId = 3 THEN -1 
                         ELSE 0 END), 0) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.CreationDate, rp.ViewCount, 
        rp.AnswerCount, rp.ActualOwnerId, rp.ActualOwnerDisplayName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.NetVotes,
    fp.CreationDate,
    fp.ActualOwnerDisplayName
FROM 
    FilteredPosts fp
WHERE 
    fp.TagRank <= 5 -- Top 5 posts per tag
ORDER BY 
    fp.CreationDate DESC, fp.NetVotes DESC
LIMIT 50; -- Adjust the limit to control pagination
This SQL query benchmarks string processing by first ranking questions by their view counts within each tag in the `Posts` table. It gathers additional data such as the actual owner of the post, comment counts, and net votes by joining the `Users`, `Votes`, and `Comments` tables. The final selection yields the top 5 posts per tag, ordered by creation date and vote tally, presenting a comprehensive view of popular content.
