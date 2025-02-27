WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN bh.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS ClosureHistory
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostWithOwnerInfo AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        us.Reputation,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        RecentPosts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserStatistics us ON u.Id = us.UserId
)
SELECT 
    pwi.Title,
    pwi.OwnerName,
    pwi.Reputation,
    pwi.CreationDate,
    pwi.CommentCount,
    pwi.UpVotes,
    pwi.DownVotes,
    CASE 
        WHEN pwi.CommentCount = 0 THEN 'No Comments'
        WHEN pwi.CommentCount > 5 THEN 'Popular'
        ELSE 'Moderate Activity'
    END AS ActivityLevel,
    (SELECT STRING_AGG(DISTINCT tt.TagName, ', ')
     FROM STRING_TO_ARRAY(
        (SELECT Tags FROM Posts WHERE Id = pwi.PostId), 
        ',') AS TagNames
     JOIN Tags tt ON tt.TagName = TagNames) AS TagsUsed
FROM 
    PostWithOwnerInfo pwi
WHERE 
    pwi.RN = 1
ORDER BY 
    pwi.Reputation DESC NULLS LAST, 
    pwi.UpVotes DESC; 

This SQL query uses several advanced constructs:
1. **Common Table Expressions (CTEs)**: to break down the logic into manageable parts — `RecentPosts`, `UserStatistics`, and `PostWithOwnerInfo`.
2. **Window Functions**: `ROW_NUMBER()` is used to rank posts for each user based on creation date.
3. **Aggregations and Case Logic**: to classify posts based on their activity and determine the number of badges.
4. **Correlated Subquery**: to retrieve tags related to each post.
5. **String Aggregation**: `STRING_AGG` to consolidate tag names.
6. **Outer Joins**: to include comments and votes information even if there are none. 

The complexities of various predicates, aggregates, and logic provide a robust benchmark for performance analysis while demonstrating the intricacies of the SQL capabilities.
