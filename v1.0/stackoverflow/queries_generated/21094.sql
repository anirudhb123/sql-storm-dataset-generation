WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 19 THEN ph.CreationDate END) AS ProtectedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    up.Reputation,
    up.BadgeCount,
    COALESCE(rv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(rv.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN phd.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN phd.ProtectedDate IS NOT NULL THEN 'Protected'
        ELSE 'Active'
    END AS PostStatus,
    rp.CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentVotes rv ON rv.PostId = rp.PostId
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ', ')) AS TagName
        FROM 
            Posts p
        WHERE 
            rp.PostId = p.Id
    ) t ON true
WHERE 
    rp.PostRank = 1 AND 
    (up.Reputation > 100 OR up.BadgeCount >= 5) AND 
    (rp.Score > 0 OR rp.CommentCount > 10)
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, up.Reputation, up.BadgeCount, 
    rv.UpVotes, rv.DownVotes, phd.ClosedDate, phd.ProtectedDate
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;

This SQL query includes the following constructs and features:
- Common Table Expressions (CTEs) for ranking posts, aggregating user reputation including badges, calculating recent votes, and determining post history status.
- Use of `ROW_NUMBER()` window function to rank posts by user.
- Conditional aggregation with `SUM(CASE ...)` to count types of votes.
- Conditional logic to determine post status (closed or protected).
- Use of string aggregation to compile tags into a single output.
- Complex predicates to filter based on user reputation and post activity.
