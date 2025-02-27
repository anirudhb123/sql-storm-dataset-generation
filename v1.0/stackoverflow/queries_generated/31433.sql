WITH UserStats AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS TagPostCount
    FROM 
        Tags tag
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY 
        tag.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        ph.Comment,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.Questions,
    us.Answers,
    us.TotalUpVotes,
    us.TotalDownVotes,
    pt.TagName,
    COALESCE(rph.Comment, 'No recent history') AS RecentComment,
    COALESCE(rph.CreationDate, 'No edits') AS LastEditDate,
    rph.UserDisplayName AS EditorName
FROM 
    UserStats us
CROSS JOIN 
    PopularTags pt
LEFT JOIN 
    RecentPostHistory rph ON us.UserId = rph.UserId AND rph.rn = 1
WHERE 
    us.Reputation > 1000 
    AND pt.TagPostCount > 5
ORDER BY 
    us.TotalUpVotes DESC, us.PostCount DESC;

### Explanation:
1. **CTE UserStats**: This collects statistics for each user, including post counts, questions, answers, and vote counts (upvotes and downvotes).
2. **CTE PopularTags**: This identifies the most popular tags based on the count of posts associated with them.
3. **CTE RecentPostHistory**: This retrieves recent changes made to posts in the last 30 days, focusing on the latest edit per post.
4. The final `SELECT` statement combines these data sources. It uses `CROSS JOIN` to associate each user with the popular tags and `LEFT JOIN` to include the most recent post history.
5. **Filtering**: Users with a reputation greater than 1000 and a significant number of posts associated with popular tags are included.
6. **Ordering**: Results are ordered by total upvotes, then by post count.
