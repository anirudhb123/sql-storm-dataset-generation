WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCountPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.UserRank,
        rp.CommentCountPerUser
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank <= 5
),
PostVoteAggregates AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS ClosuredDate,
        MAX(CASE WHEN pht.Name = 'Post Deleted' THEN ph.CreationDate END) AS DeletedDate,
        COUNT(CASE WHEN pht.Name = 'Edited Body' THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    r.ViewCount,
    r.CreationDate,
    hs.ClosuredDate,
    hs.DeletedDate,
    hs.EditCount,
    r.CommentCountPerUser
FROM 
    TopRankedPosts r
LEFT JOIN 
    PostVoteAggregates v ON r.PostId = v.PostId
LEFT JOIN 
    PostHistoryStats hs ON r.PostId = hs.PostId
WHERE 
    (hs.ClosuredDate IS NULL OR hs.DeletedDate IS NULL)
    AND r.ViewCount > 100
ORDER BY 
    r.ViewCount DESC, r.CreationDate DESC
LIMIT 100;

-- Let's also fetch Users with the most comments and their reputation
WITH UserCommentStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ucs.UserId,
    ucs.DisplayName,
    ucs.Reputation,
    ucs.TotalComments
FROM 
    UserCommentStats ucs
WHERE 
    ucs.TotalComments >= (SELECT AVG(TotalComments) FROM UserCommentStats)
ORDER BY 
    ucs.Reputation DESC, ucs.TotalComments DESC
LIMIT 50;
