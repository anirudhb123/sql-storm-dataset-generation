WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.BadgeCount,
        CASE 
            WHEN ps.UserPostRank <= 5 THEN 'Top Posts'
            ELSE 'Other Posts'
        END AS PostCategory
    FROM 
        PostStats ps
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    r.CommentCount,
    r.UpVotes,
    r.DownVotes,
    r.BadgeCount,
    r.PostCategory,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = p.Id) AS AnswerCount,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, ',')))::int) AS Tags
FROM 
    Posts p
LEFT JOIN 
    RankedPosts r ON p.Id = r.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
    AND (p.Title ILIKE '%SQL%' OR p.Body ILIKE '%SQL%') -- Related to SQL
ORDER BY 
    r.UpVotes DESC, r.CommentCount DESC
LIMIT 50;

This SQL query achieves the following:

1. **Recursive CTE** (`RecursivePostHierarchy`): Builds a hierarchy of posts to count comments and track parent-child relationships for better analytics.

2. **Post Statistics CTE** (`PostStats`): Calculates various statistics for each post, including the number of comments, upvotes, downvotes, and the count of user badges.

3. **Ranked Posts CTE** (`RankedPosts`): Categorizes posts into 'Top Posts' and 'Other Posts' based on the user's posting rank.

4. **Final SELECT**: Retrieves detailed information about posts, filtering only questions related to SQL, ordering them by their popularity based on upvotes and comments, and limiting the output to the top 50 records.

5. **Aggregations & String Manipulations**: The query uses `STRING_AGG` to join tag names for easy readability and also includes the logic to support NULL handling for various elements.
