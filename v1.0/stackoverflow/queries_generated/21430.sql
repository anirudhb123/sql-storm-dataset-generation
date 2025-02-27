WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostRanked AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
BadgesRanked AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CAST(pt.Name AS VARCHAR), ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    uv.UpVotes,
    uv.DownVotes,
    COALESCE(br.BadgeCount, 0) AS TotalBadges,
    COALESCE(br.BadgeNames, 'None') AS BadgeNames,
    pr.PostId,
    pr.Title,
    pr.Score,
    pd.PostHistoryTypes,
    pd.LastUpdate
FROM 
    Users u
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    BadgesRanked br ON u.Id = br.UserId
LEFT JOIN 
    PostRanked pr ON pr.RecentPostRank = 1 AND u.Id = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = pr.PostId
    )
LEFT JOIN 
    PostDetails pd ON pr.PostId = pd.PostId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    pr.Score DESC
LIMIT 50;

### Explanation:
- **CTEs**:
  - `UserVotes`: Counts upvotes and downvotes for each user.
  - `PostRanked`: Ranks posts created in the last year by post type and creation date.
  - `BadgesRanked`: Counts badges for each user and aggregates badge names.
  - `PostDetails`: Aggregates distinct post history types for each post along with the last update date.

- **Joins**:
  - Uses LEFT JOINs to connect users with their votes and badges as well as the most recent post they have authored.

- **COALESCE**:
  - Handles NULL values for badge count and badge names elegantly.

- **Correlated Subquery**:
  - To ensure the post retrieved belongs to the user showing the most recent post.

- **Aggregates**:
  - Uses `STRING_AGG` to concatenate names and types effectively.

This query provides a comprehensive view of user interactions with posts in the last year along with their voting behaviors and badges earned, which can be beneficial for analyzing performance.
