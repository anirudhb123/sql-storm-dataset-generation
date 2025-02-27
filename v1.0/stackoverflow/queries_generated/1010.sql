WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 5 THEN 1 END) AS FavoriteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpvoteCount - DownvoteCount AS NetVotes
    FROM 
        UserVoteStats
    WHERE 
        UpvoteCount > 5 OR DownvoteCount < 3
    ORDER BY 
        NetVotes DESC
    LIMIT 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(t.TagName, 'No Tag') AS Tag,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Tag,
    rp.ViewCount,
    rp.Score,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS TotalUpvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS TotalDownvotes
FROM 
    TopUsers up
JOIN 
    RecentPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    rp.rn = 1
ORDER BY 
    up.NetVotes DESC, rp.ViewCount DESC

