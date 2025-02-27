WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
), 
UserVoteStatistics AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(*) OVER (PARTITION BY t.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON true
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- considering only Close, Reopen, Delete, and Undelete actions
)
SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.CreationDate,
    rp.ViewCount,
    rp.Score,
    ut.Upvotes,
    ut.Downvotes,
    phd.Comment AS PostHistoryComment,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY rp.CreationDate DESC) AS RecentPostRank
FROM 
    Users u
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserVoteStatistics ut ON u.Id = ut.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    u.Reputation >= 1000 -- Users with a high reputation
    AND (ut.TotalVotes > 0 OR ut.Upvotes > 0) -- Users who have actively voted
    AND rp.rn = 1 -- Only return the most recent post for each user
ORDER BY 
    rp.CreationDate DESC;
