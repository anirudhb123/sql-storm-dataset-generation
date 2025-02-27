WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired, 1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 1  -- Start with moderator-only tags

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired, th.Level + 1
    FROM Tags t
    JOIN TagHierarchy th ON t.Id = th.ExcerptPostId  -- Assuming ExcerptPostId forms hierarchy
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
    STRING_AGG(DISTINCT th.TagName, ', ') AS RelatedTags,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN TagHierarchy th ON th.ExcerptPostId = p.Id -- Join with tag hierarchy
WHERE u.Reputation > 0
  AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate, p.Id, p.Title, p.CreationDate
ORDER BY u.Reputation DESC, PostRank ASC
LIMIT 50;

### Explanation:
1. **Recursive CTE (TagHierarchy)**: Builds a hierarchy of tags that are marked as moderator-only, recursively querying for each tag based on its `ExcerptPostId`.
   
2. **Main Query**: Joins `Users`, `Posts`, `Comments`, `Votes`, and the recursive `TagHierarchy` to gather comprehensive user and post details. 

3. **Calculations and Aggregations**:
   - Counts the number of comments for each post (`CommentCount`).
   - Sums the upvotes and downvotes using conditional aggregation.
   - Uses `STRING_AGG` to concatenate related tags.

4. **Row Number**: The `ROW_NUMBER()` window function is used to rank posts per user based on post creation date.

5. **Filtering and Sorting**: Only users with positive reputation who created posts in the last year are considered. The results are sorted based on user reputation and post rank.

6. **LIMIT**: The result is limited to the top 50 users.
