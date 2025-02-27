WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, TotalBounty DESC) AS UserRank
    FROM 
        UserStats
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score > 0 AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        DISTINCT p.Id AS PostId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason,
        p.Title
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    t.UserRank,
    p.PostId,
    p.Title AS PopularPostTitle,
    p.CommentCount,
    COALESCE(c.CloseDate, 'No Close Date') AS CloseDate,
    COALESCE(c.CloseReason, 'Not Applicable') AS CloseReason
FROM 
    TopUsers t
JOIN 
    PopularPosts p ON t.PostCount > 1
LEFT JOIN 
    ClosedPosts c ON p.PostId = c.PostId
WHERE 
    t.UserRank <= 10
ORDER BY 
    t.UserRank, p.CommentCount DESC;
