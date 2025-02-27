WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.ParentId = a.Id
    INNER JOIN 
        RecursivePosts rp ON a.Id = rp.PostId
), RankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS OwnerRank
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, u.DisplayName, rp.OwnerUserId
), FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN CommentCount > 10 THEN 'Highly Discussed'
            WHEN CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 5  -- Limit to top 5 ranked posts per user
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Owner,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.DiscussionLevel
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
WHERE 
    ph.CreationDate > (SELECT MAX(CreationDate) - INTERVAL '1 year' FROM PostHistory)
    AND ph.PostHistoryTypeId IN (10, 11)  -- Filter for posts that have been closed or reopened
ORDER BY 
    fp.CommentCount DESC,
    fp.UpVotes DESC;

This query performs the following steps:

1. **Recursive CTE (RecursivePosts)**: This part accumulates all posts, gathering answers for each question by linking parent-child relationships, filtering for questions only.
2. **Ranking and Aggregation (RankedPosts)**: It counts comments and calculates upvotes and downvotes for each question and ranks them by the number of comments per user.
3. **Filtering (FilteredPosts)**: This filters the top 5 ranked posts for each user and categorizes their discussion level based on comment count.
4. **Final Selection**: Finally, it retrieves the relevant post details along with post-history conditions, ensuring only posts impacted within the last year by specific history types are included. The result is ordered by the comment count and upvotes.
