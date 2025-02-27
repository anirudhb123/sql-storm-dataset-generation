WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 8 THEN v.PostId END) AS BountyVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    GROUP BY 
        u.Id
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        up.UserId,
        COUNT(DISTINCT up.PostId) AS ActivePostCount,
        MIN(up.CreationDate) AS FirstPostDate,
        MAX(up.CreationDate) AS LastPostDate
    FROM 
        Posts up
    WHERE 
        up.OwnerUserId IS NOT NULL
    GROUP BY 
        up.OwnerUserId
)
SELECT 
    u.Id AS UserID,
    u.DisplayName,
    u.Reputation,
    us.UpvoteCount,
    us.DownvoteCount,
    us.TotalVotes,
    us.BountyVotes,
    pa.TagName,
    phd.ClosureCount,
    phd.DeletionCount,
    ua.ActivePostCount,
    ua.FirstPostDate,
    ua.LastPostDate,
    CASE 
        WHEN us.UpvoteCount > us.DownvoteCount THEN 'More Upvotes'
        WHEN us.UpvoteCount < us.DownvoteCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VotePreference,
    CASE 
        WHEN phd.LastHistoryDate IS NOT NULL AND phd.ClosureCount > 0 THEN 'Closed Recently'
        WHEN phd.LastHistoryDate IS NULL AND phd.DeletionCount > 0 THEN 'Deleted Recently'
        ELSE 'No Recent Changes'
    END AS PostHistorySummary
FROM 
    Users u
LEFT JOIN 
    UserVoteStats us ON u.Id = us.UserId
LEFT JOIN 
    PostTags pa ON pa.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    UserActivity ua ON ua.UserId = u.Id
WHERE 
    u.Location IS NOT NULL
ORDER BY 
    u.Reputation DESC, us.UpvoteCount DESC, pa.TagName
LIMIT 100;
