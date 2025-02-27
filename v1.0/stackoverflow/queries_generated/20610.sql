WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Name, 'No Badges') AS BadgeName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, b.Name
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
    HAVING 
        COUNT(*) > 2  -- posts with multiple changes
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.UserRank,
    u.Reputation,
    COALESCE(phd.ChangeCount, 0) AS HistoricChanges,
    COALESCE(up.UpVotes, 0) AS UpVotes,
    u.BadgeName
FROM 
    RankedPosts p
JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = p.PostId
LEFT JOIN 
    (SELECT 
        PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
     FROM 
         Votes 
     GROUP BY 
         PostId) AS up ON up.PostId = p.PostId
WHERE 
    p.Rank = 1  -- Get the latest post by each user
ORDER BY 
    p.Score DESC,  
    p.ViewCount DESC NULLS LAST,
    u.Reputation DESC;

This SQL query does the following:
1. Uses a Common Table Expression (CTE) to rank posts by recent activity per user, counting the number of comments and upvotes on each.
2. Creates another CTE to summarize user reputation and badge data, generating a rank for users based on their reputation score.
3. A third CTE aggregates changes in post history, counting significant alterations made in the last six months.
4. Combines this data to provide a comprehensive output of significant posts, allowing for an exploration of user engagement, historical activity, and performance within the system, using multiple joins, groupings, and aggregation.
