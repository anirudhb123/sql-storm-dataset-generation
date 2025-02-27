WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TagStatistics AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId IN (SELECT u.Id FROM Users u WHERE u.Reputation > 100)
    GROUP BY 
        t.Id, t.TagName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Upvotes - ua.Downvotes AS NetVotes,
    ua.PostCount,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.CommentCount AS TagCommentCount,
    cp.LastClosedDate
FROM 
    UserActivity ua
LEFT JOIN 
    TagStatistics ts ON ua.PostCount > 0
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
WHERE 
    ua.UserRank <= 10
ORDER BY 
    NetVotes DESC, ua.PostCount DESC;
In this query:

1. A **Common Table Expression (CTE)** `UserActivity` summarizes user statistics, such as upvotes, downvotes, and post count, while also ranking users based on their creation date.

2. Another CTE `TagStatistics` gathers tag-related statistics, including the count of posts that include each tag, the number of comments associated with those posts, and the count of badges earned by users of high reputation.

3. The `ClosedPosts` CTE selects posts that have been closed, capturing the last closed date for each post.

4. The **final SELECT** statement combines these statistics, retrieving the top users based on their net votes and filtering those who have posted at least once.

5. It utilizes **string matching** to tie tags to posts and incorporates **GROUP BY** to aggregate data effectively.

6. The query ultimately aims to deliver insights into user activity across closed posts while weaving together disparate elements of the schema in an intricate manner, showcasing SQL's powerful capabilities in data manipulation and analysis.
