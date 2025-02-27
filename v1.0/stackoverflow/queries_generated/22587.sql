WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened' 
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
            ELSE 'Other Action' 
        END AS ActionType,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount
    FROM 
        PostHistory ph
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    CONCAT(ur.DisplayName, ' (Reputation: ', ur.Reputation, ')') AS UserDetails,
    COALESCE(ph.HistoryCount, 0) AS ActionHistoryCount,
    SUM(rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
    STRING_AGG(DISTINCT COALESCE(c.Text, 'No Comments'), '; ') AS Comments
FROM 
    RankedPosts rp
JOIN 
    Users ur ON rp.OwnerUserId = ur.Id
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
WHERE 
    rp.PostRank <= 3
    AND (rp.CommentCount > 0 OR ur.Reputation > 100)
GROUP BY 
    rp.PostId, rp.Title, ur.DisplayName, ur.Reputation, ph.HistoryCount
ORDER BY 
    NetVotes DESC, rp.CreationDate DESC
LIMIT 10;

### Explanation:
- **CTEs (Common Table Expressions)**: The query utilizes multiple CTEs for organizing data logically.
    - `RankedPosts`: Computes the rank for posts along with their comment and vote counts.
    - `UserReputation`: Details the reputation of users and the number of badges they hold.
    - `PostHistoryDetails`: Records the history of post actions, indicating if they were closed or reopened.
  
- **Aquarium of Joins**: Many outer joins combine user, post, and vote data, ensuring we capture comments and votes effectively.

- **Aggregations and Window Functions**: Net votes are calculated with a summarization within a `SUM` function, while a `ROW_NUMBER` is calculated in the `RankedPosts` CTE to rank posts.

- **String Aggregations**: Uses `STRING_AGG` to concatenate comment texts, handling potential NULLs gracefully.

- **Complicated Conditions**: The `WHERE` clause introduces filtering for recent posts and active users based on reputation, showcasing complexity in selection criteria.

- **Grand Finale**: The entire results aggregate to yield the top posts based on complex criteria, embodying the idea of performance benchmarking by amalgamating various SQL constructs.

This setup creates an intricate query that can serve as a benchmark for performance and complexity in SQL execution while drawing on the characteristics of the Stack Overflow schema.
